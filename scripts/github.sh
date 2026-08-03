#!/usr/bin/env bash
# GitHub helpers for this repo (via gh CLI). Prefer over raw git push / gh.
#
# Usage:
#   ./scripts/github.sh status
#   ./scripts/github.sh push
#   ./scripts/github.sh pr --title "..." --body "..."
#   ./scripts/github.sh pr-view
#   ./scripts/github.sh checks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/_lib.sh
source "$SCRIPT_DIR/_lib.sh"

CMD="${1:-}"
shift || true

usage() {
  cat <<'EOF'
GitHub helper (gh CLI)

Commands:
  status     Branch, remote sync, short status
  push       Push current branch (-u on first push; --force-with-lease for rewrites)
  pr         Create pull request (--title required; --body, --base optional)
  pr-view    View current branch PR
  checks     Show PR checks / recent runs

Examples:
  ./scripts/github.sh status
  ./scripts/github.sh push
  ./scripts/github.sh pr --title "Release 2.1.0" --body "## Summary\n- …"
EOF
}

github_status() {
  gg_require_git_repo
  local branch upstream

  branch="$(gg_current_branch)"
  gg_print_header "Branch"
  echo "$branch"

  gg_print_header "Remote"
  if git remote get-url origin >/dev/null 2>&1; then
    git remote -v
  else
    echo "No origin remote configured."
  fi

  upstream="$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || true)"
  if [[ -n "$upstream" ]]; then
    gg_print_header "Sync"
    git status -sb
    local ahead behind
    ahead="$(git rev-list --count "${upstream}..HEAD" 2>/dev/null || echo 0)"
    behind="$(git rev-list --count "HEAD..${upstream}" 2>/dev/null || echo 0)"
    echo "Ahead: $ahead, behind: $behind"
  else
    gg_print_header "Sync"
    echo "No upstream branch. Use: ./scripts/github.sh push"
  fi

  gg_print_header "Working tree"
  git status --short
}

github_push() {
  gg_require_git_repo
  gg_require_cmd git

  local branch
  branch="$(gg_current_branch)"

  if [[ -n "$(git status --porcelain)" ]]; then
    echo "error: working tree not clean; commit or stash before push" >&2
    git status --short >&2
    exit 1
  fi

  if [[ "$branch" == "main" || "$branch" == "master" ]]; then
    echo "warning: pushing directly to $branch" >&2
  fi

  local force=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --force-with-lease|-f)
        force=1
        shift
        ;;
      *)
        echo "error: unknown push arg: $1" >&2
        exit 1
        ;;
    esac
  done

  if [[ "$force" -eq 1 ]]; then
    echo "warning: force-with-lease push to $branch" >&2
    git push --force-with-lease
  elif git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
    git push
  else
    git push -u origin HEAD
  fi
}

github_pr() {
  gg_require_cmd gh
  gg_require_git_repo

  local title="" body="" base="main"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --title)
        title="$2"
        shift 2
        ;;
      --body)
        body="$2"
        shift 2
        ;;
      --base)
        base="$2"
        shift 2
        ;;
      *)
        echo "error: unknown argument: $1" >&2
        exit 1
        ;;
    esac
  done

  if [[ -z "$title" ]]; then
    echo "error: --title is required" >&2
    exit 1
  fi

  if [[ -z "$body" ]]; then
    body="$(cat <<EOF
## Summary
- 

## Test plan
- [ ] 
EOF
)"
  fi

  # Reuse existing PR for this head if present.
  local existing
  existing="$(gh pr list --head "$(gg_current_branch)" --json url --jq '.[0].url // empty')"
  if [[ -n "$existing" ]]; then
    echo "PR already exists: $existing"
    return 0
  fi

  gh pr create --title "$title" --body "$body" --base "$base"
}

github_pr_view() {
  gg_require_cmd gh
  gg_require_git_repo
  gh pr view --web 2>/dev/null || gh pr view
}

github_checks() {
  gg_require_cmd gh
  gg_require_git_repo
  gh pr checks 2>/dev/null || gh run list --limit 5
}

case "$CMD" in
  status)
    github_status
    ;;
  push)
    github_push "$@"
    ;;
  pr)
    github_pr "$@"
    ;;
  pr-view)
    github_pr_view
    ;;
  checks)
    github_checks
    ;;
  -h|--help|help|"")
    usage
    ;;
  *)
    echo "error: unknown command: $CMD" >&2
    usage
    exit 1
    ;;
esac
