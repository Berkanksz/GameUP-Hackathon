# Token budget

1. Never scan or read the whole project. Start from docs/PROJECT_MAP.md and docs/GRAPH.md.
2. Before editing a file run: python tools/gen_graph.py --impact <file>. Read a dependent file only if your change touches a signal, public method, exported var, group, or translation key it uses.
3. Read files by line range. Do not re-read a file you just wrote.
4. Memory graph: use search_nodes or open_nodes. Never call read_graph.
5. Load a skill or doc only when the task needs it. One at a time.
6. Validate with Godot MCP script checks and console errors first. At most one screenshot per task, only for visual work.
7. Batch related edits into one tool call.
8. Do not create extra docs, plans, or summaries unless asked.
