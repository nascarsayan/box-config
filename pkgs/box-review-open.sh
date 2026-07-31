#!/usr/bin/env bash
# Open a branch's pull request in VS Code for review.
#
# Requires being run from VS Code's integrated terminal (Remote-SSH is fine):
# that is what puts `code` on PATH with a live VSCODE_IPC_HOOK_CLI. From a plain
# ssh or detached tmux shell there is no window to talk to.
set -euo pipefail

EXT_ID='GitHub.vscode-pull-request-github'

log() { printf '[review-open] %s\n' "$*" >&2; }
die() { printf '[review-open] ERROR: %s\n' "$*" >&2; exit 1; }

# See box-gwq-review: the integrated terminal is a plain login shell, so gh is
# neither on PATH nor pointed at the sandbox credentials unless we do it here.
# PATH is baked in at build time by writeShellApplication's runtimeInputs, so
# unlike the bash installer's copy of this script there is no sandbox bin dir to
# prepend here. GH_CONFIG_DIR still gets a fallback: `box` sources
# hm-session-vars.sh and so exports it, but a bare `nix run` would not.
SANDBOX_HOME="${SANDBOX_HOME:-$HOME}"
if [ -z "${GH_CONFIG_DIR:-}" ] && [ -d "${SANDBOX_HOME}/.config/gh" ]; then
  export GH_CONFIG_DIR="${SANDBOX_HOME}/.config/gh"
fi

usage() {
  cat >&2 <<'USAGE'
usage: box-review-open [-c] [-a] [branch-or-pr-number]

Resolves the pull request for a branch and opens it in VS Code.

  (no arg)  use the current branch
  <number>  use that PR number directly
  -c        check the PR out via the extension instead of only viewing changes
  -a        also add this worktree as a folder in the current VS Code window
USAGE
}

checkout=0
add_folder=0
while [ $# -gt 0 ]; do
  case "$1" in
    -c|--checkout) checkout=1; shift ;;
    -a|--add-folder) add_folder=1; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) die "unknown option: $1" ;;
    *) break ;;
  esac
done

command -v code >/dev/null 2>&1 \
  || die "'code' not on PATH -- run this from VS Code's integrated terminal"
command -v gh >/dev/null 2>&1 || die "gh not found on PATH"
git rev-parse --git-dir >/dev/null 2>&1 || die "not inside a git repository"

remote="${SANDBOX_REVIEW_REMOTE:-origin}"
url="$(git remote get-url "$remote" 2>/dev/null)" || die "no '$remote' remote"
# Normalise https://, git@host:, and ssh://git@host/ forms down to owner/repo.
slug="$(printf '%s' "$url" \
  | sed -E 's#^(https?://[^/]+/|ssh://[^/]+/|[^@]+@[^:]+:)##; s#/+$##; s#\.git$##')"
case "$slug" in
  */*) ;;
  *) die "cannot derive owner/repo from ${remote} url: ${url}" ;;
esac
owner="${slug%%/*}"
repo="${slug#*/}"

arg="${1:-}"
if printf '%s' "$arg" | grep -qE '^[0-9]+$'; then
  pr="$arg"
else
  branch="${arg:-$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)}"
  [ -n "$branch" ] || die "detached HEAD and no branch/PR given"
  log "looking up PR for branch ${branch}"
  pr="$(gh pr list --head "$branch" --state all --json number \
          --jq 'sort_by(-.number) | .[0].number' 2>/dev/null || true)"
  [ -n "$pr" ] && [ "$pr" != "null" ] \
    || die "no pull request found for branch '${branch}' in ${owner}/${repo}"
fi

if [ "$add_folder" -eq 1 ]; then
  top="$(git rev-parse --show-toplevel)"
  log "adding ${top} to the current window"
  code --add "$top" || log "warning: could not add folder"
fi

path=/open-pull-request-changes
[ "$checkout" -eq 1 ] && path=/checkout-pull-request

# The handler regex requires exactly https://github.com/<owner>/<repo>/pull/<n>.
pr_url="https://github.com/${owner}/${repo}/pull/${pr}"
log "opening ${pr_url}"
code --open-url "vscode://${EXT_ID}${path}?uri=${pr_url}"
