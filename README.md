# junjie-xyz/skills

Codex skills for reuse.

## Install

```bash
npx skills add junjie-xyz/skills
```

## Skills

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
