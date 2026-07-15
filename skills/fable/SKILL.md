---
name: fable
description: "Calls Claude Fable 5 at high effort for concise, read-only consultation. Use only when the user explicitly invokes $fable for advice, review, analysis, drafting, or a second opinion; never use it to edit files or perform actions."
---

# Fable

Use Claude Code directly as a one-shot, read-only consultant. Keep every call focused because Fable is expensive.

## Boundary

- Invoke only after the user explicitly writes `$fable`.
- Return advice, findings, a plan, or draft text only. Never apply the output or modify any file or external state.
- Do not let Fable use tools, inspect local paths, access the network, run commands, or continue autonomously.
- Do not send credentials, tokens, secrets, or sensitive raw content without explicit user approval.
- Use exactly `claude-fable-5` with effort `high`. Do not fall back, switch models, resume a session, or retry a model/content failure.
- For routine authentication expiry only, follow the existing low-risk auth recovery flow once and retry the same command once. Stop for account switching or unclear authorization.

## Prepare Context

1. Read any required local material yourself.
2. Send one focused question and only the smallest excerpts needed to answer it. Never send an entire repository, file, conversation, or unrelated workspace rules by default.
3. Batch only tightly related questions. Make one paid call per explicit invocation.

## Command

Use the fixed system prompt unchanged so repeated calls can reuse the same prefix. Replace only the question and optional context.

```sh
cat <<'PROMPT' | "$HOME/.local/bin/claude" -p \
  --model claude-fable-5 \
  --effort high \
  --safe-mode \
  --disable-slash-commands \
  --tools "" \
  --disallowedTools "mcp__*" \
  --permission-mode plan \
  --no-session-persistence \
  --no-chrome \
  --output-format text \
  --system-prompt 'You are a read-only consultant. Use only supplied context. Never use tools, access files or networks, change state, or ask follow-up questions. Reply in the primary language of the question unless the user explicitly requests another language. Lead with the conclusion; use at most five bullets and stay within about 800 CJK characters or 500 words unless the request explicitly asks for more. Do not restate the input or reveal chain-of-thought. If context is insufficient, return FABLE_NEEDS_CONTEXT plus only the minimum missing facts.'
Question:
<one focused question>

Context:
<only necessary excerpts; omit when unnecessary>
PROMPT
```

Do not add `--max-budget-usd`; the user chose no hard dollar cap. Keep normal output as plain text.

## Result Handling

- Return Fable's answer concisely and label it as consultation when that distinction matters.
- Treat the answer as advice, not ground truth. Verify factual claims, paths, commands, and code before relying on them.
- If Fable returns `FABLE_NEEDS_CONTEXT`, report the missing facts. Do not automatically make another paid call.
- If the user asks Fable to execute a change, request a proposed approach, patch, or draft instead; do not apply it under this skill.
