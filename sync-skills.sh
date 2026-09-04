#!/usr/bin/env bash
# Symlink skills from this repo into Cursor, Claude, Codex, and Agents.
# Repo: skills/personal/* and skills/external/<author>/* (sectioned).
# Install: flat per-skill links under each tool's skills dir.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
PERSONAL="$REPO/skills/personal"
EXTERNAL="$REPO/skills/external"
NAME_LIST="$(mktemp)"
PATH_LIST="$(mktemp)"
trap 'rm -f "$NAME_LIST" "$PATH_LIST"' EXIT

register_skill() {
  local skill_dir="$1"
  local name src existing

  [[ -d "$skill_dir" ]] || return 0
  [[ -f "$skill_dir/SKILL.md" ]] || return 0

  name="$(basename "$skill_dir")"
  if [[ "$name" == ".system" ]]; then
    echo "skip reserved name: .system"
    return 0
  fi

  src="$(cd "$skill_dir" && pwd)"
  existing="$(lookup_path "$name" || true)"
  if [[ -n "$existing" ]]; then
    echo "error: duplicate skill name '$name'" >&2
    echo "  already: $existing" >&2
    echo "  also:    $src" >&2
    exit 1
  fi
  printf '%s\n' "$name" >>"$NAME_LIST"
  printf '%s\n' "$src" >>"$PATH_LIST"
}

# One level: skills/personal/<skill>/
register_personal() {
  local skill_dir
  [[ -d "$PERSONAL" ]] || return 0
  for skill_dir in "$PERSONAL"/*/; do
    register_skill "$skill_dir"
  done
}

# Two levels: skills/external/<author>/<skill>/
register_external() {
  local author_dir skill_dir
  [[ -d "$EXTERNAL" ]] || return 0
  for author_dir in "$EXTERNAL"/*/; do
    [[ -d "$author_dir" ]] || continue
    for skill_dir in "$author_dir"/*/; do
      register_skill "$skill_dir"
    done
  done
}

lookup_path() {
  local want="$1" name
  local i=0
  while IFS= read -r name; do
    i=$((i + 1))
    if [[ "$name" == "$want" ]]; then
      sed -n "${i}p" "$PATH_LIST"
      return 0
    fi
  done <"$NAME_LIST"
  return 1
}

skill_count() {
  if [[ ! -s "$NAME_LIST" ]]; then
    echo 0
    return
  fi
  wc -l <"$NAME_LIST" | tr -d ' '
}

ensure_real_skills_dir() {
  local dest_root="$1"
  local parent
  parent="$(dirname "$dest_root")"
  mkdir -p "$parent"

  if [[ -L "$dest_root" ]]; then
    echo "replacing whole-dir symlink: $dest_root"
    rm "$dest_root"
  fi
  mkdir -p "$dest_root"
}

link_skill_into() {
  local tool="$1"
  local dest_root="$2"
  local name="$3"
  local src="$4"
  local dest="$dest_root/$name"
  local replace_real="${5:-0}"

  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ -L "$dest" ]]; then
      ln -sfn "$src" "$dest"
      echo "$tool: linked $name"
      return 0
    fi
    if [[ "$replace_real" == "1" && -d "$dest" ]]; then
      rm -rf "$dest"
      ln -sfn "$src" "$dest"
      echo "$tool: replaced real dir → linked $name"
      return 0
    fi
    echo "$tool: skip $name — exists and is not a symlink"
    return 0
  fi

  ln -sfn "$src" "$dest"
  echo "$tool: linked $name"
}

link_all_into() {
  local tool="$1"
  local dest_root="$2"
  local replace_real="${3:-0}"
  local name src i

  ensure_real_skills_dir "$dest_root"

  if [[ "$(skill_count)" -eq 0 ]]; then
    echo "$tool: no skills found"
    return 0
  fi

  i=0
  while IFS= read -r name; do
    i=$((i + 1))
    src="$(sed -n "${i}p" "$PATH_LIST")"
    link_skill_into "$tool" "$dest_root" "$name" "$src" "$replace_real"
  done <"$NAME_LIST"
}

main() {
  : >"$NAME_LIST"
  : >"$PATH_LIST"

  register_personal
  register_external

  local count
  count="$(skill_count)"
  if [[ "$count" -eq 0 ]]; then
    echo "error: no skills under skills/personal or skills/external" >&2
    exit 1
  fi

  echo "syncing $count skills…"

  link_all_into "cursor" "$HOME/.cursor/skills" 1
  link_all_into "claude" "$HOME/.claude/skills" 0
  link_all_into "codex" "$HOME/.codex/skills" 0
  link_all_into "agents" "$HOME/.agents/skills" 1

  echo "done."
}

main "$@"
