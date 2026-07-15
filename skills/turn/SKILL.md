---
name: turn
description: "Create a fresh Codex thread from a compact handoff of the current conversation while preserving its model and reasoning effort. Trigger only when the user explicitly writes $turn or @turn, with or without a new-task prompt."
---

# Turn

1. Parse the invocation.
   - `$turn` or `@turn`: no new task.
   - `$turn <prompt>` or `@turn <prompt>`: preserve `<prompt>` as the new task.

2. Load and follow `${HOME}/.agents/skills/handoff/SKILL.md` without arguments. Do not pass the turn prompt to `handoff`. Capture the absolute path of the generated handoff file and verify that it exists.

3. Resolve the source thread ID with `codex_app__list_threads({})`.
   - Match the active thread whose `cwd` equals the current working directory and whose title, description, preview, or recent turns match this conversation.
   - If multiple candidates remain, use `codex_app__read_thread` to identify the exact source.
   - Stop without creating a thread if the source cannot be identified unambiguously.

4. Resolve the source model and reasoning effort from its exact local session file.
   - Under `${CODEX_HOME:-$HOME/.codex}/sessions`, use `rg --files` to find the single filename ending in `-<source_thread_id>.jsonl`. Never search for files whose contents merely mention the ID.
   - Verify that the file contains `session_meta.payload.id` exactly equal to the source thread ID.
   - Read the last `turn_context` record and capture `payload.model` and `payload.effort`.
   - Stop if the file is missing or ambiguous, the ID check fails, or either value is missing or unsupported by `codex_app__create_thread`.

5. Resolve the current Codex project with `codex_app__list_projects({})`. Require an exact path match for the current working directory. Stop if no exact project exists.

6. Build the new thread prompt with both identifiers:

   ```text
   handoff_file: <absolute handoff path>
   source_thread_id: <source thread id>
   ```

   Then append one behavior block:
   - With a turn prompt: instruct the new thread to read the handoff file first, use it as context, and execute the supplied prompt as the new task.
   - Without a turn prompt: instruct the new thread to read the handoff file only, not continue or execute unfinished work, confirm that context is loaded, and wait for the user to provide a new task.

7. Call `codex_app__create_thread` with the matched `projectId`, `target.environment.type: local`, `model` set to the source model, and `thinking` set to the source effort. Do not use `codex_app__fork_thread`.

8. After success, report the handoff path, source thread ID, source model and effort, and new thread ID. Emit `::created-thread{threadId="<new thread id>"}` on its own line. Do not navigate to, archive, or send an extra message to either thread.

If handoff generation, file verification, source resolution, model or effort resolution, project resolution, or thread creation fails, report the real failure and do not claim completion.
