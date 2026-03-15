# AGENTS.md

## Purpose

This repo stores Codex skills that can be installed with:

```bash
npx skills add junjie-xyz/skills
```

## Structure

- `skills/<name>/`: the actual skill content
- `scripts/sync-codex-skills.sh`: internal maintenance script to sync configured local skills from `${HOME}/.codex/skills`

## Rules

- Keep implementations simple.
- When adding a new skill, add its name to `SKILLS` at the top of `scripts/sync-codex-skills.sh`.
- `./scripts/sync-codex-skills.sh` is internal-only; do not present it as a user-facing install or usage command.
- Sync skills by running `./scripts/sync-codex-skills.sh` only when maintaining this repo.
- If the public skill list changes, update `README.md` in the same change.
