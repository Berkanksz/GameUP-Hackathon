---
description: Final checks before submission. Build, text, licenses, smoke test, presentation inputs.
---

# /ship_check

1. python tools/gen_graph.py --check and python tools/check_project.py. Fix failures.
2. FACTS: every FACT_ text must have a verified source in docs/FACTS_SOURCES.md. Verify unverified ones by web search against official sources (IPCC, NASA, NOAA, UNEP, UN, Turkish ministries) and soften wording if the claim is not clearly supported.
3. Smoke test through Godot MCP: run the game, play the main path of each chapter, switch language en to tr and back, pause and resume, check each ending, read console errors.
4. Export: make sure export_presets.cfg has a Windows Desktop preset (add a Web preset if time allows). If export templates are missing, tell the user to install them in Godot (Editor, Manage Export Templates). Export to export/.
5. Credits screen lists every asset from docs/ASSET_LICENSES.md that requires attribution.
6. Fill the presentation inputs in docs/SUBMISSION.md: final pitch, features, screenshots to capture, focus areas, time log.
7. Reply with a pass or fail list. Under Senden: screenshots or video the user must capture, template filling, and the submission form before 23:59 on 1 November.
