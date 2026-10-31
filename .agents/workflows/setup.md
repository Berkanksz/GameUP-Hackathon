---
description: Check and install tools, configure MCP servers, and prepare the Blender addon. Run once at the start.
---

# /setup

Work silently. Report only at the end in the standard reply block. Do not ask for permission for installs, just run them. If a command needs admin rights or fails, add it to "Senden".

1. Detect OS and shell.
2. Check versions: git, python (try python, python3, py), node, npx, uv and uvx, godot (Godot 4.3 or newer, try godot, godot4, and common install paths), blender (3.0 or newer, find the executable path).
3. Install what is missing:
   * Windows (winget): OpenJS.NodeJS.LTS, astral-sh.uv, GodotEngine.GodotEngine, BlenderFoundation.Blender, Python.Python.3.12, Git.Git. If an id fails, run winget search for it.
   * macOS (brew): brew install node uv git python, then brew install --cask godot blender.
   * Linux: use the package manager for git, python, node. uv via the official astral install script. Godot and Blender via flatpak or snap, which may need the user to run sudo.
   * After installing, PATH may be stale. Use full executable paths or tell the user to restart Antigravity.
4. Project folder: git init if missing. Create the folder layout from docs/TECH_SPEC.md section 3 (empty folders get a .gitkeep). Do not create game code here.
5. MCP config. File: global mcp_config.json (Windows: C:\Users\<user>\.gemini\antigravity\mcp_config.json, macOS and Linux: ~/.gemini/antigravity/mcp_config.json).
   * Read it. Merge the servers from mcp_config.template.json: godot, blender, memory. Never remove or change other servers. Skip a server that already exists.
   * Fill the placeholders with absolute paths: GODOT_PATH, GODOT_PROJECT_PATH (this project folder), MEMORY_FILE_PATH (this project folder plus .agents/memory.jsonl). Use forward slashes in paths.
   * On Windows, if npx servers fail to start, switch command to cmd with args /c npx ...
   * Check the godot package README (npm view @n24q02m/better-godot-mcp or its repository). If it requires an editor plugin or extra setup, do it and tell the user what to enable in Godot. If the package is broken or missing, use another maintained Godot MCP (for example godot-mcp-server) and tell the user.
6. Blender addon: download addon.py from the ahujasid/blender-mcp repository into tools/blender_addon/addon.py (verify the URL with a search if it fails). Add the manual steps to "Senden" exactly:
   * Blender: Edit, Preferences, Add-ons, Install from Disk, choose tools/blender_addon/addon.py, enable it.
   * In the 3D viewport press N, open the BlenderMCP tab, tick Poly Haven, leave Sketchfab off, click Connect.
   * Keep Blender open while working.
7. Verify each server with one harmless call: godot (project info or list scenes), blender (get scene info), memory (create entity "project:higher_ground" with one observation). If a server tool is not visible, tell the user to open Manage MCP Servers and refresh, or restart Antigravity.
8. Run python tools/gen_graph.py and python tools/check_project.py to confirm Python works.
9. Final reply: one line per tool and server with OK or the problem, then "Senden" steps.
