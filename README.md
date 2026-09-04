# AI Scaffolding

Personal fleet of agent skills + plans. This repo is the source of truth.
`./sync-skills.sh` symlinks them into Cursor, Claude, and Codex.

## Layout

```
skills/personal/              # mine (− BkS👨‍💻 in description)
skills/external/<author>/…    # other authors (vendored; grouped by GitHub owner)
agents/
plans/
sync-skills.sh
check-external-updates.sh
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
- Others → `skills/external/<author>/<name>/` (author = GitHub owner from [skills.sh](https://www.skills.sh))
- Commit, push, `./sync-skills.sh` on other machines

Check upstream without applying:

```bash
./check-external-updates.sh
# or /check-external-updates
```

Sources map: `skills/external/SOURCES.tsv`. To refresh a skill, replace its folder from upstream, then commit.

Note: `make-interfaces-feel-better` is no longer on Emil’s GitHub pack (not in the check). `caveman` is filed under `mattpocock/` but checked against [juliusbrussee/caveman](https://github.com/juliusbrussee/caveman) (actual publisher on skills.sh).

Cloud Agents don’t see `~/.cursor/skills` — copy skills into the project or bake into the worker.
