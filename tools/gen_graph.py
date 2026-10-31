#!/usr/bin/env python3
"""Generate docs/GRAPH.md, a compact dependency and signal map of a Godot project.

Usage:
  python tools/gen_graph.py                write docs/GRAPH.md
  python tools/gen_graph.py --impact PATH  list files affected by changing PATH
  python tools/gen_graph.py --check        exit 1 if docs/GRAPH.md is out of date

Limits: node path couplings ($Path, get_node) are not tracked. Record them in the memory graph.
"""
import argparse
import re
import sys
from collections import defaultdict, deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "docs" / "GRAPH.md"
SKIP_DIRS = {".git", ".godot", ".agents", ".agent", "addons", "docs", "tools", "art_source", "export"}
NODE_EXTS = {".gd", ".tscn", ".tres"}
DEP_EXTS = {".gd", ".tscn", ".tres", ".gdshader"}

RE_CLASS = re.compile(r"^class_name\s+(\w+)", re.M)
RE_EXTENDS = re.compile(r"^extends\s+([\w.]+)", re.M)
RE_SIGNAL = re.compile(r"^signal\s+(\w+)", re.M)
RE_RES = re.compile(r"""(?:preload|load)\(\s*["'](res://[^"']+)["']""")
RE_EMIT = re.compile(r"\b(\w+)\.emit\(")
RE_EMIT_OLD = re.compile(r"""emit_signal\(\s*["'](\w+)["']""")
RE_CONNECT = re.compile(r"\b(\w+)\.connect\(")
RE_EXT_RES = re.compile(r'\[ext_resource[^\]]*?path="(res://[^"]+)"')
RE_AUTOLOAD_SECTION = re.compile(r"^\[autoload\]\s*\n(.*?)(?=^\[|\Z)", re.M | re.S)
RE_AUTOLOAD_LINE = re.compile(r'^(\w+)="\*?(res://[^"]+)"', re.M)


def strip_comments(text: str) -> str:
    """Remove # comments while keeping # inside string literals."""
    lines = []
    for line in text.splitlines():
        quote = None
        cut = len(line)
        for i, ch in enumerate(line):
            if quote:
                if ch == quote and line[i - 1] != "\\":
                    quote = None
            elif ch in "\"'":
                quote = ch
            elif ch == "#":
                cut = i
                break
        lines.append(line[:cut])
    return "\n".join(lines)


def collect_files() -> list[Path]:
    files = []
    for path in ROOT.rglob("*"):
        if not path.is_file() or path.suffix not in NODE_EXTS:
            continue
        if any(part in SKIP_DIRS for part in path.relative_to(ROOT).parts[:-1]):
            continue
        files.append(path)
    return sorted(files)


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def short(res_path: str) -> str:
    return res_path.removeprefix("res://")


def parse_autoloads() -> dict[str, str]:
    project = ROOT / "project.godot"
    if not project.exists():
        return {}
    section = RE_AUTOLOAD_SECTION.search(project.read_text(encoding="utf-8"))
    if not section:
        return {}
    return {name: short(path) for name, path in RE_AUTOLOAD_LINE.findall(section.group(1))}


def build_graph():
    autoloads = parse_autoloads()
    info = {}
    for path in collect_files():
        raw = path.read_text(encoding="utf-8", errors="replace")
        code = strip_comments(raw) if path.suffix == ".gd" else raw
        info[rel(path)] = {"suffix": path.suffix, "code": code}

    # Names that other scripts can reference: class_name declarations and autoloads.
    name_owner = dict(autoloads)
    declared_signals = {}
    for key, item in info.items():
        if item["suffix"] != ".gd":
            continue
        code = item["code"]
        cls = RE_CLASS.search(code)
        ext = RE_EXTENDS.search(code)
        item["class"] = cls.group(1) if cls else ""
        item["extends"] = ext.group(1) if ext else ""
        item["signals"] = RE_SIGNAL.findall(code)
        if cls:
            name_owner[cls.group(1)] = key
        for name in item["signals"]:
            declared_signals.setdefault(name, key)

    deps = defaultdict(set)
    emitters = defaultdict(set)
    listeners = defaultdict(set)

    for key, item in info.items():
        code = item["code"]
        if item["suffix"] == ".gd":
            for res in RE_RES.findall(code):
                if Path(res).suffix in DEP_EXTS:
                    deps[key].add(short(res))
            for name, owner in name_owner.items():
                if owner != key and re.search(rf"\b{name}\b", code):
                    deps[key].add(owner)
            for name in RE_EMIT.findall(code) + RE_EMIT_OLD.findall(code):
                if name in declared_signals:
                    emitters[name].add(key)
            for name in RE_CONNECT.findall(code):
                if name in declared_signals:
                    listeners[name].add(key)
        else:
            for res in RE_EXT_RES.findall(code):
                if Path(res).suffix in DEP_EXTS:
                    deps[key].add(short(res))

    deps = {k: {d for d in v if d in info and d != k} for k, v in deps.items()}
    used_by = defaultdict(set)
    for src, targets in deps.items():
        for target in targets:
            used_by[target].add(src)
    return info, autoloads, deps, used_by, declared_signals, emitters, listeners


def render() -> str:
    info, autoloads, deps, used_by, declared, emitters, listeners = build_graph()
    out = ["# GRAPH", "", "Auto generated by tools/gen_graph.py. Do not edit.", ""]
    out.append("Autoloads: " + (", ".join(f"{n}={p}" for n, p in sorted(autoloads.items())) or "none"))
    out += ["", "## Files", "Format: path | extends | class | signals | uses | used_by", ""]
    for key in sorted(info):
        item = info[key]
        parts = [key]
        if item["suffix"] == ".gd":
            parts += [item.get("extends") or "", item.get("class") or "", ",".join(item.get("signals", []))]
        else:
            parts += ["", "", ""]
        parts.append(",".join(sorted(deps.get(key, []))))
        parts.append(",".join(sorted(used_by.get(key, []))))
        out.append(" | ".join(parts))
    out += ["", "## Signals", "Format: name (declared in) | emit | listen", ""]
    for name in sorted(declared):
        emit = ",".join(sorted(emitters.get(name, []))) or "NO_EMITTER"
        listen = ",".join(sorted(listeners.get(name, []))) or "NO_LISTENER"
        out.append(f"{name} ({declared[name]}) | {emit} | {listen}")
    return "\n".join(out) + "\n"


def resolve_target(query: str, info: dict):
    query = short(query).strip("/")
    if query in info:
        return query
    matches = [k for k in info if k.endswith(query)]
    return matches[0] if len(matches) == 1 else None


def impact(query: str) -> int:
    info, _, _, used_by, declared, emitters, listeners = build_graph()
    target = resolve_target(query, info)
    if not target:
        print(f"Not found or ambiguous: {query}")
        return 1
    seen = {target}
    queue = deque([(target, 0)])
    levels = defaultdict(list)
    while queue:
        node, depth = queue.popleft()
        for parent in sorted(used_by.get(node, [])):
            if parent not in seen:
                seen.add(parent)
                levels[depth + 1].append(parent)
                queue.append((parent, depth + 1))
    print(f"Target: {target}")
    for depth in sorted(levels):
        label = "Direct dependents" if depth == 1 else f"Indirect (level {depth})"
        print(f"{label}: {', '.join(levels[depth])}")
    if not levels:
        print("Dependents: none")
    for name in sorted(n for n, p in declared.items() if p == target):
        print(f"Signal {name}: emit={sorted(emitters.get(name, []))} listen={sorted(listeners.get(name, []))}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--impact", metavar="PATH")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    if args.impact:
        return impact(args.impact)
    content = render()
    if args.check:
        current = OUT.read_text(encoding="utf-8") if OUT.exists() else ""
        if current != content:
            print("GRAPH.md is out of date. Run: python tools/gen_graph.py")
            return 1
        print("GRAPH.md is up to date.")
        return 0
    OUT.write_text(content, encoding="utf-8")
    print(f"Wrote {rel(OUT)} ({content.count(chr(10))} lines)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
