# junjie-xyz/skills

Codex skills for reuse.

## Skills

| Skill | Full Name | Description |
| --- | --- | --- |
| [`turn`](skills/turn/SKILL.md) | New Thread Handoff | Create a new Codex thread with a compact handoff, preserving the current model and reasoning effort. |
| [`fable`](skills/fable/SKILL.md) | Fable Advisor | Ask Claude Fable 5 for help while keeping token usage to an absolute minimum. |
| [`ask`](skills/ask/SKILL.md) | Ask User Questions with Inline HTML | An alternative to Codex's `request_user_input` and Claude Code's `AskUserQuestion` tools, with rich interactive content and batched questions. |
| [`sub`](skills/sub/SKILL.md) | Subagent Delegation | Send a task to a Codex subagent. |
| [`name`](skills/name/SKILL.md) | Context-Aware Thread Renaming | Rename the current Codex thread based on the conversation context and optionally mark it as important. |
| [`tinypng`](skills/tinypng/SKILL.md) | TinyPNG Image Optimization | Compress, resize, and convert PNG, JPEG, WebP, and AVIF images with the TinyPNG API. |
| [`max`](skills/max/SKILL.md) | Max-Reasoning Advisor | Ask a Codex subagent to think deeply about a hard or stuck problem. |

## Install

Install all skills:

```bash
npx skills add junjie-xyz/skills
```

Install a single skill:

```bash
npx skills add junjie-xyz/skills --skill <skill-name>
```

### `turn` dependency

`turn` requires Matt Pocock's [`handoff`](https://github.com/mattpocock/skills/tree/main/skills/productivity/handoff) skill. Install both skills:

```bash
npx skills add https://github.com/mattpocock/skills --skill handoff
npx skills add junjie-xyz/skills --skill turn
```

## Repo Layout

- `skills/`: installed skill contents
- `scripts/`: internal maintenance scripts for this repo

`scripts/sync-codex-skills.sh` is for internal repo maintenance, not for skill consumers.
