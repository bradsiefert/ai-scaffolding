# Cursor skills + fleet sync

Context from [Cursor skills vs commands](821a1d7c-f93c-46ad-a812-414e28f94771) (2026-08-31). Use this when standing up global skills / a sync repo.

## Commands vs skills

Both exist. Commands were not renamed.

- **Commands** — legacy. Flat markdown in `.cursor/commands/`. You type `/`. Docs page is gone. Still loads.
- **Skills** — current. Folder + `SKILL.md`. Agent can auto-apply, or `/skill-name`. Scripts, references, assets.

Skills are a superset. `disable-model-invocation: true` = old command behavior (human `/` only).

New workflows → skills. Built-in `/migrate-to-skills` converts commands.

## Where skills live

| Location | Scope |
|---|---|
| `.cursor/skills/` or `.agents/skills/` | this project |
| `~/.cursor/skills/` or `~/.agents/skills/` | this Mac, every local project |
| `~/.claude/skills/`, `~/.codex/skills/` | also loaded globally |

Cloud Agents / remote SSH do **not** get `~/.cursor/skills/`. For those: project skills in the repo, or bake into the worker image.

Each skill:

```
~/.cursor/skills/
└── my-skill/
    └── SKILL.md
```

## Fleet repo (Theo pattern)

Source of truth is a git repo of skills, not a custom distributor. Theo started a sync script, got it buggy, stopped. Now: edit → commit/push → tell the agent “apply to the fleet.”

Skill scopes he uses:

- `universal/` — every machine
- Claude-only — Claude Code machines
- command-center — leader box only

**Simpler version for this repo:** skills in git + symlink or `sync.sh` after `git pull`.

```
ai-scaffolding/   # or a dedicated fleet folder later
  skills/
    file-pr/SKILL.md
  sync.sh         # optional; symlink is enough if every machine wants the same set
```

Install onto the machine:

```bash
ln -sfn ~/Sites/personal/ai-scaffolding/skills ~/.cursor/skills
```

Same repo can also feed `~/.claude/skills` and `~/.codex/skills`.

- Symlink = live; edit once, all tools see it.
- Copy/rsync = re-run after pull.
- Agent-applies = Theo’s way.

Per-machine subsets need metadata or a script. Same-everywhere does not.

Don’t commit secrets. If a skill needs a token, require it and fail loud.

## Intent for this repo

This scaffolding should hold portable agent kit (skills, AGENTS.md, plans) that can be cloned or symlinked onto any machine — not project-specific DS work.

Kit skills end the frontmatter `description` with `- BkS👨‍💻` (hover tooltip). Body does not need it.
