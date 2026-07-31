#!/usr/bin/env bash
# Prepare a branch for PR-style review: fetch it, materialise a gwq worktree and
# print that worktree's path on stdout. Every human-facing line goes to stderr so
# the caller can safely do:  cd "$(box-gwq-review <branch>)"
set -euo pipefail

log() { printf '[gwq-review] %s\n' "$*" >&2; }
die() { printf '[gwq-review] ERROR: %s\n' "$*" >&2; exit 1; }

# Invoked from whatever shell the user is in -- typically VS Code's integrated
# terminal, a plain login bash where the sandbox bin dir is NOT on PATH and gh's
# credentials are invisible (they live under the sandbox config dir, not
# ~/.config/gh). So bootstrap both instead of assuming an activated sandbox.
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
usage: box-gwq-review [-b] <branch | pr-number | new-branch-name> [base-branch]

Creates or reuses a gwq worktree and prints its path on stdout.

  <branch>       an existing branch, fetched from the remote
  <pr-number>    all digits: resolved to that pull request's head branch, and the
                 PR's own base branch becomes the review base
  -b <name>      create a new branch forked from the freshly fetched base

[base-branch] overrides the base. Otherwise: the PR's base for a PR, else
origin/HEAD, else main, else master.
USAGE
}

NEW_BRANCH=0
while [ $# -gt 0 ]; do
  case "$1" in
    -b|--new-branch) NEW_BRANCH=1; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) die "unknown option: $1" ;;
    *) break ;;
  esac
done
[ $# -ge 1 ] || { usage; exit 2; }

target="$1"
base_arg="${2:-}"
remote="${SANDBOX_REVIEW_REMOTE:-origin}"

command -v gwq >/dev/null 2>&1 || die "gwq not found on PATH"
command -v jq  >/dev/null 2>&1 || die "jq not found on PATH"
git rev-parse --git-dir >/dev/null 2>&1 || die "not inside a git repository"
git remote get-url "$remote" >/dev/null 2>&1 || die "no '$remote' remote in this repository"

# An all-digits argument is a PR number; anything else is a branch name -- to be
# created when -b is given, otherwise expected to already exist on the remote.
mode="branch"
pr=""
pr_cross=0
if [ "$NEW_BRANCH" -eq 1 ]; then
  mode="new"
  branch="$target"
elif printf '%s' "$target" | grep -qE '^[0-9]+$'; then
  mode="pr"
  pr="$target"
else
  branch="$target"
fi

if [ "$mode" = "pr" ]; then
  command -v gh >/dev/null 2>&1 || die "gh not found on PATH; needed to resolve PR #${pr}"
  log "resolving PR #${pr}"
  pr_json="$(gh pr view "$pr" --json headRefName,baseRefName,isCrossRepository,state 2>/dev/null || true)"
  [ -n "$pr_json" ] || die "cannot read PR #${pr} -- wrong number, or no access to this repo?"
  branch="$(printf '%s' "$pr_json" | jq -r '.headRefName // empty')"
  [ -n "$branch" ] || die "PR #${pr} has no head branch"
  [ "$(printf '%s' "$pr_json" | jq -r '.isCrossRepository')" = "true" ] && pr_cross=1
  # A PR knows its own base, which beats guessing via origin/HEAD.
  if [ -z "$base_arg" ]; then
    base_arg="$(printf '%s' "$pr_json" | jq -r '.baseRefName // empty')"
  fi
  log "PR #${pr} [$(printf '%s' "$pr_json" | jq -r '.state')]: ${branch} -> ${base_arg:-?}"
fi

# origin/HEAD is frequently unset (it is only written by an initial clone, not by
# later fetches), so fall back to the conventional names before giving up.
resolve_base() {
  local h c
  if [ -n "$base_arg" ]; then
    printf '%s' "${base_arg#"${remote}"/}"
    return 0
  fi
  if h="$(git symbolic-ref --short "refs/remotes/${remote}/HEAD" 2>/dev/null)"; then
    printf '%s' "${h#"${remote}"/}"
    return 0
  fi
  # Unset: ask the remote what its default branch is and cache the answer, so
  # this costs one network round-trip once rather than on every invocation.
  if git remote set-head "$remote" -a >/dev/null 2>&1 &&
     h="$(git symbolic-ref --short "refs/remotes/${remote}/HEAD" 2>/dev/null)"; then
    printf '%s' "${h#"${remote}"/}"
    return 0
  fi
  for c in main master; do
    if git show-ref --verify --quiet "refs/remotes/${remote}/${c}" ||
       git ls-remote --exit-code --heads "$remote" "$c" >/dev/null 2>&1; then
      printf '%s' "$c"
      return 0
    fi
  done
  return 1
}
base="$(resolve_base)" || die "cannot determine base branch; pass it as the 2nd argument"

log "fetching base ${remote}/${base}"
git fetch --quiet "$remote" "+refs/heads/${base}:refs/remotes/${remote}/${base}" \
  || log "warning: could not refresh ${remote}/${base}; using the cached ref"

remote_ref="refs/remotes/${remote}/${branch}"

# Bring the branch into existence locally. Explicit refspecs rather than a plain
# `git fetch origin <branch>`, so refs/remotes/<remote>/... is guaranteed to exist
# afterwards -- that is what the branch gets created from and tracks.
fetch_or_create_branch() {
  case "$mode" in
    new)
      if git show-ref --verify --quiet "refs/heads/${branch}"; then
        die "branch '${branch}' already exists; drop -b to use it, or choose another name"
      fi
      log "creating ${branch} from ${remote}/${base}"
      git branch --quiet "$branch" "refs/remotes/${remote}/${base}" \
        || die "cannot create branch '${branch}' from ${remote}/${base}"
      ;;
    pr)
      # Prefer refs/heads, which gives the branch a natural upstream so a later
      # `,gwq <branch>` fast-forwards it. But it is frequently absent: a fork PR
      # never had one on our remote, and a merged PR's branch is usually deleted
      # (both PR #784 and #866 here). refs/pull/<n>/head survives all of those.
      if [ "$pr_cross" -eq 0 ] && \
         git fetch --quiet "$remote" "+refs/heads/${branch}:${remote_ref}" 2>/dev/null; then
        log "fetched ${remote}/${branch}"
      else
        remote_ref="refs/remotes/${remote}/pr/${pr}"
        log "head branch unavailable on ${remote}; fetching refs/pull/${pr}/head"
        git fetch --quiet "$remote" "+refs/pull/${pr}/head:${remote_ref}" \
          || die "cannot fetch refs/pull/${pr}/head for PR #${pr}"
      fi
      ensure_local_branch
      ;;
    *)
      if git fetch --quiet "$remote" "+refs/heads/${branch}:${remote_ref}" 2>/dev/null; then
        log "fetched ${remote}/${branch}"
      elif git show-ref --verify --quiet "refs/heads/${branch}"; then
        # Gone from the remote but still here: typical of a branch deleted after
        # its PR merged. Reviewing it locally is still legitimate, so degrade
        # rather than fail. Pointing remote_ref at the local branch makes the
        # fast-forward check below a no-op.
        log "warning: ${remote}/${branch} no longer exists (deleted after merge?); using the local branch"
        remote_ref="refs/heads/${branch}"
      else
        die "branch '${branch}' not found on ${remote}, and no local branch of that name"
      fi
      ensure_local_branch
      ;;
  esac
}

# Which worktree, if any, currently has the branch checked out.
wt_holding_branch() {
  git worktree list --porcelain 2>/dev/null | awk -v b="refs/heads/${branch}" '
    /^worktree / { p = substr($0, 10) }
    $0 == "branch " b { print p; exit }
  '
}

ff_local_branch() {
  local holder
  holder="$(wt_holding_branch)"
  if [ -z "$holder" ]; then
    git branch --quiet --force "$branch" "$remote_ref" \
      && log "fast-forwarded ${branch} to ${remote_ref#refs/remotes/}" \
      || log "warning: could not fast-forward ${branch}"
    return 0
  fi
  # Checked out somewhere: `git branch -f` refuses, so move it via the worktree,
  # and only when there is nothing uncommitted to lose.
  if git -C "$holder" diff --quiet 2>/dev/null && git -C "$holder" diff --cached --quiet 2>/dev/null; then
    git -C "$holder" merge --ff-only "$remote_ref" >/dev/null 2>&1 \
      && log "fast-forwarded ${branch} to ${remote}/${branch}" \
      || log "warning: could not fast-forward ${branch} in ${holder}"
  else
    log "warning: ${holder} has uncommitted changes; leaving ${branch} where it is"
  fi
}

# Create the local branch explicitly rather than leaning on git's DWIM in
# `git worktree add <path> <branch>`: DWIM refuses outright ("invalid reference")
# when more than one remote publishes the same branch name, and it gives no say
# in what happens to an already-existing stale local branch.
ensure_local_branch() {
  local local_sha remote_sha
  if ! git show-ref --verify --quiet "refs/heads/${branch}"; then
    log "creating local branch ${branch} tracking ${remote_ref#refs/remotes/}"
    git branch --quiet --track "$branch" "$remote_ref" \
      || die "cannot create local branch '${branch}'"
    return 0
  fi
  local_sha="$(git rev-parse --verify --quiet "refs/heads/${branch}" || true)"
  remote_sha="$(git rev-parse --verify --quiet "$remote_ref" || true)"
  [ -n "$local_sha" ] && [ -n "$remote_sha" ] || return 0
  [ "$local_sha" = "$remote_sha" ] && return 0
  if git merge-base --is-ancestor "$local_sha" "$remote_sha" 2>/dev/null; then
    ff_local_branch
  else
    log "warning: local ${branch} has diverged from ${remote}/${branch}"
    log "         reviewing the LOCAL state; 'git reset --hard ${remote}/${branch}' in the"
    log "         worktree to match the remote exactly"
  fi
}

# gwq prints a plain "No worktrees found in <dir>" line rather than `[]` when the
# basedir is empty, which makes jq exit non-zero and -- under `set -e` -- would
# abort on first use in a fresh sandbox. So sniff for a JSON array first.
wt_for_branch() {
  local json
  json="$(gwq list --json -g 2>/dev/null || true)"
  case "$json" in
    \[*) ;;
    *) return 0 ;;
  esac
  printf '%s' "$json" \
    | jq -r --arg b "$branch" '.[] | select(.branch == $b) | .path' 2>/dev/null \
    | head -n1
}

fetch_or_create_branch

# `gwq add` errors out when the directory already exists, so reuse takes priority.
wt="$(wt_for_branch)"
if [ -n "$wt" ] && [ -d "$wt" ]; then
  log "reusing worktree ${wt}"
else
  log "creating worktree for ${branch}"
  gwq add "$branch" >&2 || die "gwq add failed for '${branch}'"
  wt="$(wt_for_branch)"
  [ -n "$wt" ] && [ -d "$wt" ] || die "worktree path not resolvable after gwq add"
  created=1
fi

# Reap merged worktrees in the background after a new one is created.
#
# Both redirections matter. The ,gwq shim reads our stdout via command
# substitution, which blocks until *every* holder of that pipe closes it -- an
# inherited stdout in the child would hang the cd until gc finished. And stdin
# must be detached so a backgrounded child never competes for the terminal.
spawn_gc() {
  # Resolved off PATH rather than as <sandbox>/bin/box-gwq-gc: under nix the two
  # helpers are separate store paths, so there is no shared bin dir to assume.
  local gc log_dir="${XDG_CACHE_HOME:-${SANDBOX_HOME}/.cache}/box"
  gc="$(command -v box-gwq-gc 2>/dev/null || true)"
  [ -n "$gc" ] && [ -x "$gc" ] || return 0
  mkdir -p "$log_dir" 2>/dev/null || return 0
  if command -v setsid >/dev/null 2>&1; then
    setsid "$gc" --skip "$wt" >>"${log_dir}/gwq-gc.log" 2>&1 </dev/null &
  else
    nohup "$gc" --skip "$wt" >>"${log_dir}/gwq-gc.log" 2>&1 </dev/null &
  fi
  log "reaping merged worktrees in the background (${log_dir}/gwq-gc.log)"
}
[ "${created:-0}" -eq 1 ] && spawn_gc

# Stash the base inside the worktree's gitdir -- not the working tree, so it can
# never show up in the diff being reviewed. Editor tooling reads it from here.
gitdir="$(git -C "$wt" rev-parse --absolute-git-dir)"
printf '%s\n' "${remote}/${base}" >"${gitdir}/box-review-base"

mb="$(git -C "$wt" merge-base "${remote}/${base}" HEAD 2>/dev/null || true)"
if [ -n "$mb" ]; then
  log "review base ${remote}/${base} @ ${mb:0:12}"
  if [ "$mode" = "new" ]; then
    log "new branch, no commits yet"
  else
    git -C "$wt" --no-pager diff --stat "${mb}...HEAD" >&2 || true
  fi
else
  log "warning: no merge-base between HEAD and ${remote}/${base}"
fi

printf '%s\n' "$wt"
