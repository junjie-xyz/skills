# Inline Visualization Rules

- For `::codex-inline-vis{file="<name>.html"}`, write the fragment to `~/.codex/visualizations/YYYY/MM/DD/<CODEX_THREAD_ID>/<name>.html`.
- Do not use a workspace-relative `.codex/visualizations` directory.
- Use `CODEX_THREAD_ID` for the thread directory and verify that the file exists there before emitting the directive.
- Keep the file as a literal HTML fragment without `<!doctype>`, `<html>`, `<head>`, or `<body>`.
- Resolve the active `visualize:visualize` skill directory from its available-skill source path, then run `<visualize-skill-dir>/scripts/render.py`. Do not infer the path from the plugin root.
- Treat `render.py` success as syntax validation only; confirm that the visualization renders inside the conversation before reporting success.
- Keep `::codex-inline-vis{file="<name>.html"}` on its own line and use the exact filename.
- For maps, inspect the rendered result and verify that geometry, labels, and points are visible before replying.
