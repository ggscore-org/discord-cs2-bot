#!/usr/bin/env bash
# Create a git commit in this repo (preferred over raw `git commit`).
#
# Usage:
#   ./scripts/git.sh -F /tmp/messages/foo.msg [paths...]
#   ./scripts/git.sh --message-file /tmp/messages/foo.msg
#   COMMIT_MSG_FILE=/tmp/messages/foo.msg ./scripts/git.sh [paths...]
#
# Message file: first line = subject, blank line, then body.
# Agents must write messages under /tmp/messages/ (not into the repo).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/_lib.sh
source "$SCRIPT_DIR/_lib.sh"

MSG_FILE="${COMMIT_MSG_FILE:-}"
PATHS=()

usage() {
  cat <<'EOF'
Usage:
  ./scripts/git.sh -F /tmp/messages/<name>.msg [paths...]
  ./scripts/git.sh --message-file /tmp/messages/<name>.msg

Writes commit from a message file (prefer /tmp/messages/*.msg).
Optional paths are git-add'ed before commit.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -F|--message-file)
      MSG_FILE="${2:-}"
      if [[ -z "$MSG_FILE" ]]; then
        echo "error: -F/--message-file requires a path" >&2
        exit 1
      fi
      shift 2
      ;;
    --)
      shift
      PATHS+=("$@")
      break
      ;;
    -m|--message)
      echo "error: inline -m is disabled; write the message to /tmp/messages/<name>.msg and pass -F" >&2
      exit 1
      ;;
    *)
      PATHS+=("$1")
      shift
      ;;
  esac
done

gg_require_git_repo
gg_require_cmd git

if [[ -z "$MSG_FILE" ]]; then
  echo "error: message file required (-F /tmp/messages/<name>.msg or COMMIT_MSG_FILE=...)" >&2
  usage >&2
  exit 1
fi

if [[ ! -f "$MSG_FILE" ]]; then
  echo "error: message file not found: ${MSG_FILE}" >&2
  exit 1
fi

# Soft preference: warn if not under /tmp/messages/
case "$MSG_FILE" in
  /tmp/messages/*) ;;
  *)
    echo "warning: preferred location is /tmp/messages/<name>.msg (got: ${MSG_FILE})" >&2
    ;;
esac

if [[ ${#PATHS[@]} -gt 0 ]]; then
  git add -- "${PATHS[@]}"
fi

if git diff --cached --quiet; then
  echo "Nothing staged. Stage changes first, e.g.:" >&2
  echo "  ${0} -F ${MSG_FILE} <paths...>" >&2
  exit 1
fi

gg_check_blocked_staged

gg_print_header "Message"
sed -n '1,20p' "$MSG_FILE"

gg_print_header "Diff summary"
git diff --cached --stat

gg_print_header "Commit"
git commit -F "$MSG_FILE"

gg_print_header "Status"
git status -sb
