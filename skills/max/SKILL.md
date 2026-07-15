---
name: max
description: "Escalate a blocked or user-marked problem to a gpt-5.6-sol subagent with max reasoning effort, then return verified options to the main agent. Trigger when the user writes @max or $max, or when a normal attempt still leaves the root cause unknown, failures repeat, or a high-impact tradeoff cannot be resolved confidently. Do not trigger merely because a task is complex."
---

# Max

Use a max-effort subagent as a read-only problem-solving escalation. Keep execution and final responsibility with the main agent.

## Workflow

1. Identify the problem to escalate.
   - For `@max <task>` or `$max <task>`, use `<task>`.
   - For `<task> @max` or `<task> $max`, use the nearest clearly marked task.
   - Trigger implicitly only after a normal attempt still has no supported root cause, failures repeat, or a material tradeoff remains unsafe to guess.
   - Do not trigger for ordinary complexity, and do not repeat the same escalation unless new evidence appears.

2. Build a self-contained prompt containing:
   - goal and success criteria;
   - current state and relevant paths or artifacts;
   - observed evidence and exact failures;
   - approaches already tried;
   - constraints and the specific decision or diagnosis needed.

3. Call `spawn_agent` with:

   ```json
   {
     "task_name": "max_reasoning",
     "message": "<self-contained prompt>",
     "agent_type": "default",
     "fork_turns": "none",
     "model": "gpt-5.6-sol",
     "reasoning_effort": "max",
     "service_tier": "priority"
   }
   ```

4. Tell the subagent to inspect with read-only tools when useful, compare plausible explanations, cite evidence, and return a recommended next action with risks and verification steps. It must not edit files or change external state.

5. Wait for the result when the current task depends on it. Check the recommendation against available evidence, resolve conflicts, and let the main agent perform any authorized implementation.

## Boundaries

- If `spawn_agent` or the requested model/effort is unavailable, report the exact limitation; do not silently substitute another model or effort.
- A max-effort recommendation does not bypass authorization, safety, repository, tool, or verification rules.
- Publishing, deleting, payments, permission changes, approvals, account switching, and other high-risk actions still require the usual confirmation.
