---
name: write-pr
description: >-
  Drafts a pull request title and body from the current branch and prints them
  in chat for review. Use when the user asks to write a PR description, draft a
  PR, or run /write-pr. Does not push or create the PR — follow with /create-pr.
  - BkS👨‍💻
disable-model-invocation: true
---

Draft a PR title and body in chat only. Do not push, create a branch, or run `gh pr create`.

## Steps

1. Quick commit check: `git status` / `git status -sb`. If the working tree is dirty (uncommitted or untracked changes), stop and report: **You need to commit your changes first.** Do not invent commits. Do not draft the PR.

2. If clean, gather the rest of the context in parallel:
   - `git diff [base]...HEAD`
   - `git log [base]...HEAD`
   - Default base: `main` (or `master` if that is the default branch)

3. Print a short title and body for the user to edit in chat:

   ```markdown
   ## Summary
   <1-3 bullet points of what changed and why>

   ## Test plan
   - [ ] <checklist items>
   ```

4. End with: edit the draft if needed, then run `/create-pr` (paste the final title + body if they are not already in this thread).
