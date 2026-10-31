---
description: Rebuild GRAPH.md and align PROJECT_MAP.md and the memory graph with the real code.
---

# /sync_graph

1. python tools/gen_graph.py
2. Compare the Signals section of docs/GRAPH.md with the signals table in docs/PROJECT_MAP.md. Fix PROJECT_MAP.md where it drifted.
3. List signals marked NO_EMITTER or NO_LISTENER. Decide for each: implement, remove, or mark planned in PROJECT_MAP.md.
4. Update memory entities for any module whose public contract changed.
5. Reply with the drift list in the standard block. Keep it short.
