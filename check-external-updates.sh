#!/usr/bin/env bash
# Compare vendored external SKILL.md files to GitHub upstream (report only).
# Does not download or overwrite. Exit 1 if any updates or errors.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
SOURCES="$REPO/skills/external/SOURCES.tsv"
EXTERNAL="$REPO/skills/external"

if [[ ! -f "$SOURCES" ]]; then
  echo "error: missing $SOURCES" >&2
  exit 1
fi

hash_file() {
  local f="$1"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$f" | awk '{print $1}'
  else
    sha256sum "$f" | awk '{print $1}'
  fi
}

fetch_remote_skill() {
  local repo="$1"
  local path="$2"
  local out="$3"
  local url rel
  local curl_bin
  curl_bin="$(command -v curl || echo /usr/bin/curl)"

  if [[ "$path" == "." ]]; then
    rel="SKILL.md"
  else
    rel="${path%/}/SKILL.md"
  fi

  for branch in main master; do
    url="https://raw.githubusercontent.com/${repo}/${branch}/${rel}"
    if "$curl_bin" -fsSL --max-time 20 "$url" -o "$out" 2>/dev/null; then
      return 0
    fi
  done
  return 1
}

find_local_skill() {
  local skill="$1"
  local match
  match="$(find "$EXTERNAL" -type f -path "*/${skill}/SKILL.md" 2>/dev/null | head -1)"
  if [[ -n "$match" ]]; then
    echo "$match"
    return 0
  fi
  return 1
}

updates=0
errors=0
checked=0

echo "Checking external skills against GitHub…"
echo

while IFS=$'\t' read -r skill repo path || [[ -n "${skill:-}" ]]; do
  [[ -z "${skill:-}" ]] && continue
  [[ "$skill" == \#* ]] && continue

  checked=$((checked + 1))
  local_skill=""
  local_skill="$(find_local_skill "$skill" || true)"
  if [[ -z "$local_skill" ]]; then
    echo "error   $skill — local SKILL.md not found under skills/external/"
    errors=$((errors + 1))
    continue
  fi

  remote_tmp="$(mktemp)"
  if ! fetch_remote_skill "$repo" "$path" "$remote_tmp"; then
    echo "error   $skill — could not fetch $repo ($path/SKILL.md)"
    rm -f "$remote_tmp"
    errors=$((errors + 1))
    continue
  fi

  local_hash="$(hash_file "$local_skill")"
  remote_hash="$(hash_file "$remote_tmp")"
  rm -f "$remote_tmp"

  if [[ "$local_hash" == "$remote_hash" ]]; then
    echo "ok      $skill"
  else
    echo "update  $skill — upstream differs ($repo)"
    updates=$((updates + 1))
  fi
done <"$SOURCES"

echo
echo "Checked $checked · updates $updates · errors $errors"

if [[ "$updates" -gt 0 || "$errors" -gt 0 ]]; then
  exit 1
fi
exit 0
