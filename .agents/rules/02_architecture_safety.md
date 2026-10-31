# Architecture and safety

1. Structure truth: docs/GRAPH.md (auto generated). Intent and contracts: docs/PROJECT_MAP.md and the memory graph.
2. Feature folders under features/. A feature never touches another feature's nodes or private vars. Cross feature talk goes through EventBus signals or the public methods listed in PROJECT_MAP.md.
3. Signal up, call down. Children emit, parents call.
4. No hardcoded node paths across scenes. Use @export node refs or groups.
5. Do not rename or delete a signal, public method, exported var, group, input action, translation key, or autoload without running --impact and fixing every user in the same task.
6. One task, one feature. No drive by refactors or formatting changes in other files.
7. After each task: validate, run python tools/gen_graph.py, update PROJECT_MAP.md if a contract changed, update touched memory entities, tick docs/TASKS.md.
8. Commit after each verified task: git add -A, then git commit with a short English message (feat:, fix:, chore:).
9. If a change breaks something, stop and fix it before starting anything new. Use git to revert if needed.
