#!/usr/bin/env bash
# Shared helpers for web repo scripts.

set -euo pipefail

gg_root() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  printf '%s' "$(cd "$script_dir/.." && pwd)"
}

gg_cd_root() {
  cd "$(gg_root)"
}

gg_require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: required command not found: $cmd" >&2
    exit 1
  fi
}

gg_require_git_repo() {
  gg_cd_root
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "error: not a git repository" >&2
    exit 1
  fi
}

gg_print_header() {
  printf '\n== %s ==\n' "$1"
}

gg_current_branch() {
  git branch --show-current
}

gg_check_blocked_staged() {
  if git diff --cached --name-only \
    | grep -Ev '^\.env\.(example|coolify\.example|local\.example)$' \
    | grep -E '(^|/)\.env($|\.)|credentials\.json|secrets\.json|\.pem$|\.key$' >/dev/null 2>&1; then
    echo "error: blocked secrets staged for commit" >&2
    git diff --cached --name-only >&2
    exit 1
  fi
}
