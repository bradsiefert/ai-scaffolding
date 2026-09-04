---
name: check-external-updates
description: >-
  Runs check-external-updates.sh to compare vendored external skills against
  GitHub upstream and reports which have updates. Use when the user asks to
  check skill updates, or run /check-external-updates. Does not apply updates.
  - BkS👨‍💻
disable-model-invocation: true
---

Check whether vendored external skills differ from GitHub upstream. Do not apply updates.

## Steps

1. From the ai-scaffolding repo root, run:

   ```bash
   ./check-external-updates.sh
   ```

2. Summarize the output for the user:
   - List skills marked `update`
   - List skills marked `error`
   - Note how many are `ok`

3. If updates exist, tell the user how to refresh a skill:
   - Replace `skills/external/<author>/<skill>/` from upstream (e.g. `npx skills add <owner/repo> --skill <name>` into a temp dir, then copy)
   - Commit the change
   - No `./sync-skills.sh` needed for content-only refreshes

Do not download or overwrite skill folders unless the user explicitly asks to apply a specific update.
