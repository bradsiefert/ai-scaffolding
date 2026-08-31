# AI Scaffolding
Starting structure for AI-assisted projects: agent instructions, conventions, and plans you drop in so the next repo isn't a blank slate.

## Structure
```
ai-scaffolding/
├── agents/        # AGENTS.md and other AI instruction files
├── skills/        # Portable Cursor/Claude/Codex skills (SKILL.md folders)
├── plans/         # Project plans and specs generated with AI assistance
└── sync.sh        # Symlink installer for this machine
```

## Authorship
Skills in this kit end the frontmatter `description` with `- BkS👨‍💻` (shows in the hover tooltip). Body does not need it.

## Install
```bash
git clone <repo> ~/Sites/personal/ai-scaffolding
cd ~/Sites/personal/ai-scaffolding
./sync.sh
```

What `sync.sh` does:

- **Cursor** — whole-dir: `skills/` → `~/.cursor/skills`
- **Claude / Codex** — per-skill links into `~/.claude/skills` and `~/.codex/skills` (keeps existing skills; never touches Codex `.system`)

Manual Cursor equivalent:

```bash
ln -sfn ~/Sites/personal/ai-scaffolding/skills ~/.cursor/skills
```

Cloud Agents / remote SSH do **not** see `~/.cursor/skills`. For those: copy skills into the project, or bake them into the worker image.

## Why
A playbook is something you read. Scaffolding is something you stand up. I kept losing these plans, so they live here now — a kit I can clone, copy from, and grow.

## Status
Early days. More coming eventually.
