#!/usr/bin/env bash
# Delete gwq worktrees (and their local branches) whose work has already landed.
#
# Merged-detection, in order:
#   1. GitHub PR state == MERGED. Authoritative, and the only signal that works
#      with squash merges -- a squash-merged branch is NOT an ancestor of the base,
#      so git alone reports it as unmerged and would never reap anything.
#   2. Otherwise: the branch tip is an ancestor of the base ref. Works offline.
#
# Deliberately conservative, because this runs unattended: anything with
# uncommitted or untracked content is skipped, as is the base branch, the main
# worktree, whatever the main checkout has checked out, detached worktrees, and
# any path outside gwq's basedir.
set -euo pipefail

# PATH is baked in at build time by writeShellApplication's runtimeInputs, so
# unlike the bash installer's copy of this script there is no sandbox bin dir to
# prepend here. GH_CONFIG_DIR still gets a fallback: `box` sources
# hm-session-vars.sh and so exports it, but a bare `nix run` would not.
SANDBOX_HOME="${SANDBOX_HOME:-$HOME}"
if [ -z "${GH_CONFIG_DIR:-}" ] && [ -d "${SANDBOX_HOME}/.config/gh" ]; then
  export GH_CONFIG_DIR="${SANDBOX_HOME}/.config/gh"
fi

DRY=0
SKIP_PATH=""
usage() {
  cat >&2 <<'USAGE'
usage: box-gwq-gc [-n] [--skip <path>]

Removes gwq worktrees whose pull request is merged, plus their local branches.

  -n, --dry-run   report what would be removed, change nothing
      --skip      never touch this worktree path (used by box-gwq-review to
                  protect the worktree it just created and cd'd into)
USAGE
}
while [ $# -gt 0 ]; do
  case "$1" in
    -n|--dry-run) DRY=1; shift ;;
    --skip) SKIP_PATH="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done

ts() { date '+%Y-%m-%dT%H:%M:%S%z' 2>/dev/null || echo "-"; }
log() { printf '[gwq-gc %s] %s\n' "$(ts)" "$*"; }

git rev-parse --git-dir >/dev/null 2>&1 || { log "not in a git repository; nothing to do"; exit 0; }
command -v gwq >/dev/null 2>&1 || { log "gwq not found; nothing to do"; exit 0; }

remote="${SANDBOX_REVIEW_REMOTE:-origin}"

# Every path comparison below must be canonicalised. `git worktree list` reports
# resolved physical paths while gwq reports symlinked ones -- on an NFS home,
# /cb/home/<user>/ws is a symlink to /net/<server>/.../ws. Comparing them raw
# makes the basedir guard match nothing (so gc silently reaps nothing) and, far
# worse, makes --skip fail to protect the worktree the caller just cd'd into.
canon() { readlink -f -- "$1" 2>/dev/null || printf '%s' "$1"; }

# Only ever touch worktrees gwq itself created.
basedir="$(gwq config get worktree.basedir 2>/dev/null | tr -d '\r' || true)"
case "$basedir" in
  /*) ;;
  *) log "cannot determine gwq worktree.basedir; refusing to remove anything"; exit 0 ;;
esac
basedir="$(canon "$basedir")"
[ -n "$SKIP_PATH" ] && SKIP_PATH="$(canon "$SKIP_PATH")"

base=""
if h="$(git symbolic-ref --short "refs/remotes/${remote}/HEAD" 2>/dev/null)"; then
  base="${h#"${remote}"/}"
else
  for c in main master; do
    git show-ref --verify --quiet "refs/remotes/${remote}/${c}" && { base="$c"; break; }
  done
fi
[ -n "$base" ] || { log "cannot determine base branch; refusing to remove anything"; exit 0; }

main_wt="$(canon "$(git worktree list --porcelain | awk '/^worktree /{print substr($0,10); exit}')")"
main_branch="$(git -C "$main_wt" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"

# path<TAB>branch, skipping detached entries (no branch to reason about).
entries="$(git worktree list --porcelain | awk '
  /^worktree /{ p = substr($0, 10); b = "" }
  /^branch /  { b = substr($0, 8); sub(/^refs\/heads\//, "", b); print p "\t" b }
')"

removed=0; kept=0
while IFS=$'\t' read -r wt br; do
  [ -n "$wt" ] && [ -n "$br" ] || continue
  wt="$(canon "$wt")"
  [ "$wt" = "$main_wt" ] && continue
  case "$wt" in "$basedir"/*) ;; *) continue ;; esac
  [ -n "$SKIP_PATH" ] && [ "$wt" = "$SKIP_PATH" ] && { log "skip ${br}: just created"; kept=$((kept+1)); continue; }
  [ "$br" = "$base" ] && continue
  [ -n "$main_branch" ] && [ "$br" = "$main_branch" ] && continue

  if [ -n "$(git -C "$wt" status --porcelain 2>/dev/null)" ]; then
    log "skip ${br}: uncommitted or untracked changes"
    kept=$((kept+1)); continue
  fi

  merged=""; pr_merged=0
  if git merge-base --is-ancestor "refs/heads/${br}" "refs/remotes/${remote}/${base}" 2>/dev/null; then
    merged="ancestor of ${remote}/${base}"
  elif command -v gh >/dev/null 2>&1; then
    state="$(gh pr list --head "$br" --state all --json state \
               --jq 'map(select(.state=="MERGED")) | .[0].state // empty' 2>/dev/null || true)"
    if [ "$state" = "MERGED" ]; then
      merged="PR merged (squash)"
      pr_merged=1
    fi
  fi
  [ -n "$merged" ] || { kept=$((kept+1)); continue; }

  if [ "$DRY" -eq 1 ]; then
    log "would remove ${br} (${merged}) -> ${wt}"
    removed=$((removed+1)); continue
  fi

  if git worktree remove "$wt" 2>/dev/null; then
    # A squash-merged branch looks unmerged to git, so -d refuses it. -D is only
    # justified by positive evidence the work is already on the base.
    if git branch -d "$br" >/dev/null 2>&1; then
      :
    elif [ "$pr_merged" -eq 1 ] && git branch -D "$br" >/dev/null 2>&1; then
      :
    else
      log "removed worktree for ${br} but kept the local branch"
    fi
    log "removed ${br} (${merged})"
    removed=$((removed+1))
  else
    log "could not remove worktree ${wt}; leaving ${br} alone"
    kept=$((kept+1))
  fi
done <<EOT
${entries}
EOT

git worktree prune >/dev/null 2>&1 || true
gwq prune >/dev/null 2>&1 || true
if [ "$DRY" -eq 1 ]; then
  log "done (dry run): ${removed} would be removed, ${kept} kept"
else
  log "done: ${removed} removed, ${kept} kept"
fi
