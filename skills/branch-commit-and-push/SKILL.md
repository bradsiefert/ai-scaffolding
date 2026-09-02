---
name: branch-commit-and-push
description: >-
  Creates a descriptive branch from main/master if needed, stages all changes,
  commits with a short descriptive message, and pushes. Use when the user has
  changes on main and wants a branch + commit + push, or run
  /branch-commit-and-push. Does not open a PR. - BkS👨‍💻
disable-model-invocation: true
---

Create a branch if needed, then commit and push. Do not open a PR.

## Steps

1. Check `git status` / current branch.

2. If there is nothing to commit, stop and say so.

3. If the current branch is `main` or `master`: create a descriptive branch from current HEAD (name from the changes) and check it out. If already on a feature branch, stay on it.

4. Stage everything, commit with a short descriptive message, and push with `-u` if needed (`git push -u origin HEAD`).

## Guardrails

- Do not force-push.
- Do not skip hooks.
- Never update git config.
- Do not create a PR (use `/write-pr` then `/create-pr` for that).
