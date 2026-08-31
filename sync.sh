#!/usr/bin/env bash
# Install this repo's skills onto Cursor, Claude Code, and Codex.
# Cursor: whole-dir symlink. Claude/Codex: per-skill links (preserve existing).
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
SRC="$REPO/skills"

link_cursor() {
  local dest="$HOME/.cursor/skills"
  mkdir -p "$HOME/.cursor"

  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ -L "$dest" ]]; then
      local target
      target="$(readlink "$dest")"
      if [[ "$target" == "$SRC" ]]; then
        echo "cursor: already linked → $dest"
        return 0
      fi
      echo "cursor: replacing symlink $dest → $target"
      ln -sfn "$SRC" "$dest"
      echo "cursor: linked $SRC → $dest"
      return 0
    fi
    echo "cursor: refuse — $dest exists and is not a symlink to this repo" >&2
    exit 1
  fi

  ln -sfn "$SRC" "$dest"
  echo "cursor: linked $SRC → $dest"
}

# Per-skill link into an existing skills dir. Skip real dirs; overwrite symlinks.
link_skill_into() {
  local tool="$1"
  local dest_root="$2"
  local name="$3"
  local src="$SRC/$name"
  local dest="$dest_root/$name"

  mkdir -p "$dest_root"

  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ -L "$dest" ]]; then
      ln -sfn "$src" "$dest"
      echo "$tool: linked $name → $dest"
      return 0
    fi
    echo "$tool: skip $name — $dest exists and is not a symlink"
    return 0
  fi

  ln -sfn "$src" "$dest"
  echo "$tool: linked $name → $dest"
}

link_per_skill() {
  local tool="$1"
  local dest_root="$2"

  if [[ ! -d "$SRC" ]]; then
    echo "error: $SRC missing" >&2
    exit 1
  fi

  local found=0
  for skill_dir in "$SRC"/*/; do
    [[ -d "$skill_dir" ]] || continue
    local name
    name="$(basename "$skill_dir")"
    # Never touch Codex system builtins if someone names a skill ".system"
    if [[ "$name" == ".system" ]]; then
      echo "$tool: skip .system"
      continue
    fi
    found=1
    link_skill_into "$tool" "$dest_root" "$name"
  done

  if [[ "$found" -eq 0 ]]; then
    echo "$tool: no skills in $SRC"
  fi
}

main() {
  if [[ ! -d "$SRC" ]]; then
    echo "error: $SRC missing — add skills first" >&2
    exit 1
  fi

  link_cursor
  link_per_skill "claude" "$HOME/.claude/skills"
  link_per_skill "codex" "$HOME/.codex/skills"
}

main "$@"
