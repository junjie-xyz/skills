---
name: name
description: "Generate a concise title from the current conversation, immediately rename the active Codex thread, and toggle its important marker through an argument. Trigger on @name, @name 1, $name, requests to rename the current thread, or requests to mark or unmark a thread as important."
---

# Rename Current Thread

1. Generate a clear, specific, distinctive title from the main goal of the conversation, prioritizing the most recent active task. Include the main subject and at least one of its action, outcome, or scope. Preserve the key name of any relevant project, module, document, or platform. Do not include `@name`, `$name`, or their arguments in the title.
2. Ensure the title is distinguishable from other threads. Avoid generic titles such as "Handle issue," "Modify code," "Update document," "Skill changes," or "Requirements discussion." Prefer "Improve name thread-title rules" over "Modify skill."
3. Remove leading whitespace, repeated leading `❤️` markers, and whitespace immediately following them to obtain the base title.
4. Parse the invocation arguments:
   - If the invocation contains the standalone argument `1`, set the title to `❤️ <base title>`.
   - Otherwise, set the title to `<base title>`, removing any important marker.
5. Call `codex_app__set_thread_title` with `title` and omit `threadId` so only the current thread is renamed.
6. After the tool succeeds, briefly confirm the new title. If the tool is unavailable or fails, report the failure accurately and do not claim completion.

Use the conversation's primary language for the title.
