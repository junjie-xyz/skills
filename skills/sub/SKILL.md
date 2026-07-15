---
name: sub
description: "Delegate a user-marked task to a subagent through spawn_agent. Trigger when the user writes @sub or $sub, including suffix usage like 'Complete this task, @sub'."
---

# Sub

## Overview

Treat `@sub` or `$sub` as an explicit request to delegate the marked task to `spawn_agent`.

## Workflow

1. Decide the task to delegate.
   - `@sub <task>` / `$sub <task>`: delegate `<task>`.
   - `<task>，@sub` / `<task> $sub`: delegate the preceding task.
   - If several tasks are mixed, delegate only the nearest clearly marked task. Ask only when the split is risky.

2. Spawn the right role.
   - `explorer`: read-only inspection.
   - `worker`: bounded edits or verification with clear file/module ownership.
   - default: other general delegation.

3. Keep the prompt self-contained.
   Include goal, relevant paths, expected output, and constraints. For `worker`, say it must not revert others' edits and must adapt to concurrent changes.

4. Integrate only when needed.
   Wait if the main answer depends on the result; otherwise continue non-overlapping work. Do not redo the delegated work unless it fails.

## Boundaries

- This skill does not bypass tool rules. If `spawn_agent` is unavailable in the current runtime, say delegation cannot be performed here and handle the task locally only if the user still wants that.
- Subagents cannot approve high-risk actions. Publishing, deleting, payments, permission changes, irreversible writes, account switching, and unclear authorization still require user confirmation.
- Do not create a new Codex thread for `@sub`; use subagent delegation, not thread management tools.
