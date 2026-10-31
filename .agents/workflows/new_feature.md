---
description: Implement one feature or task safely without breaking other parts. Use for every build task.
---

# /new_feature

Input: the task name or the next unchecked item in docs/TASKS.md.

1. Read only that task and its module section in docs/PROJECT_MAP.md. Do not open other docs unless the task needs them.
2. Memory graph: search_nodes for each module you will touch.
3. python tools/gen_graph.py --impact <file> for each existing file you will change.
4. Implement inside the owning feature folder. Follow the rules. Add translation keys in en and tr if any text is involved. Log assets if any are added.
5. Validate with Godot MCP script checks and console errors. Run the scene once if it is gameplay. Fix every error and warning you caused.
6. python tools/gen_graph.py, then update PROJECT_MAP.md contracts and memory entities.
7. python tools/check_project.py if text or assets changed.
8. Tick the item in docs/TASKS.md. Commit.
9. Reply with the standard block.
