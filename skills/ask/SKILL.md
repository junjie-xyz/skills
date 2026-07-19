---
name: ask
description: Clarify requirements through batched interactive HTML questionnaires. Use when the user explicitly invokes @Ask or @ask, selects the Ask Skill, or explicitly says "ask me questions." Do not trigger for ordinary clarification requests without one of these explicit signals. Supports localized text, rich HTML, SVG, flowchart, and mockup options, with direct submission in Codex or copy-only standalone output.
---

# Ask

Turn unresolved decisions that affect execution into compact interactive questionnaires. Each page collects one batch of answers; handle dependencies across conversation turns rather than inside the page.

## Workflow

1. Identify unresolved questions whose answers would change the approach or result.
2. Map dependencies. Put only currently answerable, mutually independent questions in the same batch. Do not implement cross-batch conditional logic in HTML.
3. Infer the language of the user's current input and select a supported locale. Honor an explicit language request when present.
4. Copy `assets/example-config.json` to `/tmp/codex/YYYY-MM-DD/`, set its permissions to `0600`, then change only the batch ID, submit title, and question data.
5. Render the fixed template with `scripts/render_ask.py` and pass the selected locale through `--locale`; do not regenerate page code.
6. When a response beginning with `Ask batch:` arrives, update the known constraints. Generate another HTML batch only if dependent questions remain; otherwise resume the original task or briefly confirm that questioning is complete.

## Question design

- Support `single`, `multi`, `text`, and `textarea` questions.
- A batch may contain multiple independent questions; each question should ask for one decision.
- Write questions and options in the same language as the selected UI locale. For unsupported languages, preserve the user's language for question content and use English for fixed UI text.
- Describe meaningful differences between options. Mark a recommendation with `recommended: true`, and enable free-form input with `allowOther: true` when useful.
- Add a `preview` only when it makes comparison materially clearer. Previews support `html` and `svg` for mockups or flowcharts, but export only the selected option, not internal preview state.
- Keep option layout adaptive: cards with descriptions or previews use at most two columns and collapse to one on narrow screens; short-title-only cards may auto-fit; `Other` spans the full row.
- Do not allow scripts, event attributes, iframes, remote resources, or executable URLs inside previews.

## Localization

- Built-in locales are `en` (English), `zh-Hans` (Mandarin Chinese), `hi` (Hindi), `es` (Spanish), and `ar` (Arabic).
- Let the AI choose the locale from the user's current input and pass it explicitly to the renderer. Do not infer language from browser settings.
- `zh`, `zh-CN`, and `zh-Hans-CN` normalize to `zh-Hans`; common regional variants of English, Hindi, Spanish, and Arabic normalize to their base locale.
- The CLI `--locale` value overrides an optional `locale` field in the config. The default is `en`.
- Arabic uses right-to-left layout automatically.

## Rendering

In Codex:

1. Read the bundled `references/visualization.md` completely.
2. Write the fragment to the current thread's visualization directory:

```sh
python3 <skill-dir>/scripts/render_ask.py --config <config.json> --locale <locale> --output <thread-visualization-dir>/ask-<batch-id>.html
```

3. Validate the fragment with the bundled visualize `scripts/render.py`, then render it with `::codex-inline-vis{file="ask-<batch-id>.html"}`.

When Codex inline visualization is unavailable, generate a standalone page:

```sh
python3 <skill-dir>/scripts/render_ask.py --config <config.json> --locale <locale> --output /tmp/codex/YYYY-MM-DD/ask-<batch-id>.html --standalone
```

## Results

- In Codex, show only the submit action. It calls `window.openai.sendFollowUpMessage()` and does not use the clipboard.
- In a standalone page, show only the copy-result action. It copies the Markdown answer list and does not provide submission.
- Include only the batch ID, questions, and answers in the result. Do not repeat the original task.
