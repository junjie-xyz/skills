# junjie-xyz/skills

Codex skills for reuse.

## Install

```bash
npx skills add junjie-xyz/skills
```

## Skills

### `ask`

Clarify requirements through batched, localized interactive questionnaires.

Use `$ask` or `@ask`, or say `ask me questions`.

### `fable`

Ask Claude Fable 5 for focused advice, review, analysis, or writing help while keeping paid usage as low as possible. It does not change files or take actions.

Use `$fable`.

### `max`

Ask a Codex subagent to think deeply about a hard or stuck problem.

Use `$max` or `@max`. It may also run automatically after repeated failures.

### `name`

Rename the current Codex thread based on its context, and add or remove its important marker.

Use `$name` to rename it or `$name 1` to mark it as important.

### `sub`

Send a task to a Codex subagent.

Put `$sub` or `@sub` before or after the task.

### `turn`

Start a new Codex thread with the context, model, and reasoning effort from the current thread.

Use `$turn`, with an optional new task after it.

### `tinypng`

Compress and optimize PNG, JPEG, WebP, and AVIF images with the TinyPNG/Tinify HTTP API.

Use it when you want Codex to compress an image, optionally resize it, convert format, or preserve metadata.

Example prompts:

```text
Use $tinypng to compress ./hero.png
Use $tinypng to compress ./hero.png and set width to 128
Use $tinypng to convert ./banner.png to webp
```

## Repo Layout

- `skills/`: installed skill contents
- `scripts/`: internal maintenance scripts for this repo

`scripts/sync-codex-skills.sh` is for internal repo maintenance, not for skill consumers.
