# AI Scaffolding

Personal fleet of agent skills + plans. This repo is the source of truth.
`./sync-skills.sh` symlinks them into Cursor, Claude, and Codex.

## Layout

```
skills/personal/   # mine (− BkS👨‍💻 in description)
skills/external/   # other authors (vendored copies)
agents/            # AGENTS.md
plans/
sync-skills.sh
```

## Setup

```bash
git clone <repo> ~/Sites/personal/ai-scaffolding
cd ~/Sites/personal/ai-scaffolding
./sync-skills.sh
```

Links each skill into `~/.cursor/skills`, `~/.claude/skills`, `~/.codex/skills`, and `~/.agents/skills`. Re-run after adding or renaming a skill folder. Content edits are live (symlinks).

## Add / update skills

- Mine → `skills/personal/<name>/`
- Others → `skills/external/<name>/`
- Commit, push, `./sync-skills.sh` on other machines

Cloud Agents don’t see `~/.cursor/skills` — copy skills into the project or bake into the worker.
