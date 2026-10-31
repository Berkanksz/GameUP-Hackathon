#!/usr/bin/env python3
"""Pre ship checks for text and asset licenses.

Usage:
  python tools/check_project.py            run all checks
  python tools/check_project.py text       translation keys only
  python tools/check_project.py licenses   asset license ledger only

Exit code 1 when any check fails.
"""
import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CSV_PATH = ROOT / "translations" / "strings.csv"
LEDGER = ROOT / "docs" / "ASSET_LICENSES.md"
ASSETS = ROOT / "assets"
SKIP_DIRS = {".git", ".godot", ".agents", ".agent", "addons", "docs", "tools", "art_source", "export"}
KEY_PATTERN = re.compile(r"\b(?:UI|MONO|FACT|CHOICE|END|CH|ITEM)_[A-Z0-9_]+\b")
ASSET_SKIP_SUFFIXES = {".import", ".uid", ".md", ".gitkeep"}
REQUIRED_LOCALES = ("en", "tr")


def load_translations() -> dict[str, dict[str, str]]:
    with CSV_PATH.open(encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle))
    return {row["keys"]: row for row in rows if row.get("keys")}


def used_keys() -> set[str]:
    found = set()
    for path in ROOT.rglob("*"):
        if not path.is_file() or path.suffix not in {".gd", ".tscn", ".tres"}:
            continue
        if any(part in SKIP_DIRS for part in path.relative_to(ROOT).parts[:-1]):
            continue
        found.update(KEY_PATTERN.findall(path.read_text(encoding="utf-8", errors="replace")))
    return found


def check_text() -> int:
    if not CSV_PATH.exists():
        print("TEXT: translations/strings.csv not found")
        return 1
    table = load_translations()
    used = used_keys()
    problems = []
    for key in sorted(used - set(table)):
        problems.append(f"missing key: {key}")
    for key, row in sorted(table.items()):
        for locale in REQUIRED_LOCALES:
            value = (row.get(locale) or "").strip()
            if not value:
                problems.append(f"empty {locale}: {key}")
            elif value.upper().startswith("TODO"):
                problems.append(f"placeholder {locale}: {key}")
            elif re.search(r"[\u2013\u2014]", value):
                problems.append(f"dash character in {locale}: {key}")
    unused = sorted(set(table) - used)
    for problem in problems:
        print("TEXT FAIL:", problem)
    if unused:
        print(f"TEXT INFO: {len(unused)} keys not referenced in code or scenes yet: {', '.join(unused[:8])}{' ...' if len(unused) > 8 else ''}")
    print(f"TEXT: {len(table)} keys, {len(problems)} problems")
    return 1 if problems else 0


def is_listed(rel: str, ledger: str) -> bool:
    """True if the file, or any parent folder written as its own entry, is in the ledger."""
    parts = rel.split("/")
    for depth in range(len(parts), 1, -1):
        candidate = "/".join(parts[:depth])
        if re.search(rf"(?<![\w/.]){re.escape(candidate)}/?(?![\w./])", ledger):
            return True
    return False


def check_licenses() -> int:
    if not ASSETS.exists():
        print("LICENSES: no assets folder yet")
        return 0
    ledger = LEDGER.read_text(encoding="utf-8") if LEDGER.exists() else ""
    missing = []
    for path in sorted(ASSETS.rglob("*")):
        if not path.is_file() or path.suffix in ASSET_SKIP_SUFFIXES or path.name.startswith("."):
            continue
        rel = path.relative_to(ROOT).as_posix()
        if not is_listed(rel, ledger):
            missing.append(rel)
    for item in missing:
        print("LICENSE FAIL: not in ledger:", item)
    print(f"LICENSES: {len(missing)} assets missing from docs/ASSET_LICENSES.md")
    return 1 if missing else 0


def main() -> int:
    mode = sys.argv[1] if len(sys.argv) > 1 else "all"
    results = []
    if mode in ("all", "text"):
        results.append(check_text())
    if mode in ("all", "licenses"):
        results.append(check_licenses())
    return 1 if any(results) else 0


if __name__ == "__main__":
    sys.exit(main())
