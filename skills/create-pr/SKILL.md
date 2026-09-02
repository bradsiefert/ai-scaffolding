---
name: create-pr
description: >-
  Creates a pull request from a reviewed title and body in chat: branches off
  main/master if needed, pushes, and runs gh pr create. Use when the user asks
  to open or create a PR, or run /create-pr, after /write-pr. - BkS👨‍💻
disable-model-invocation: true
---

Create a PR from a reviewed title + body in this chat (or pasted in the user message). Do not invent a new draft unless the user asks.

## Steps

1. Resolve title and body from this conversation or the user message. If either is missing, stop and ask for them.

2. If the working tree is dirty: stop and ask to commit first. Do not invent commits.

3. If the current branch is `main` or `master`: create a descriptive branch from current HEAD and check it out. Do not force-checkout or overwrite unrelated work.

4. Push with `-u` if needed: `git push -u origin HEAD`

5. Create the PR with `gh pr create`, passing title and body via HEREDOC. Return the PR URL.

## Guardrails

- Do not force-push.
- Do not skip hooks.
- Never update git config.
- Use the `gh` CLI for all GitHub PR operations.
