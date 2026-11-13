# Interactive zsh config. Kept as .zsh so `zsh -n` can check it and there is no
# nix ''${...} escaping to get wrong.

alias git_current_branch="git rev-parse --abbrev-ref HEAD"
alias ggpush='git push origin $(git_current_branch)'

mkcd() {
  if [ $# -eq 0 ]; then
    printf 'usage: mkcd <directory>\n' >&2
    return 1
  fi
  mkdir -p -- "$1" && cd -- "$1"
}

# $SSHPASS if already exported, else the pass entry.
if command -v pass >/dev/null 2>&1; then
  sshp() {
    SSHPASS="${SSHPASS:-$(pass show "${BOX_SSH_PASS_ENTRY:-ssh/default}")}" sshpass -e ssh "$@"
  }
fi

if (( $+commands[eza] )); then
  alias ls='eza -lh --group-directories-first --icons=auto'
fi

DISABLE_MAGIC_FUNCTIONS=true
DISABLE_UPDATE_PROMPT=true

# ~800 generated aliases (k, kgp, ...): box ships the pinned kubectl-aliases
# input here; host mode loads them through zinit instead.
if [[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/box/kubectl_aliases" ]]; then
  source "${XDG_CONFIG_HOME:-$HOME/.config}/box/kubectl_aliases"
fi

# kubecolor, but only for subcommands it can safely colorize. A bare
# `alias kubectl=kubecolor` hangs exec/attach/port-forward/logs -f/get -w, because
# kubecolor buffers stdout and that is incompatible with raw pty streaming.
#
# A function, not an alias: it dispatches per subcommand, and the typed word stays
# `kubectl` so _comps[kubectl] applies with no extra wiring.
if (( $+commands[kubecolor] )); then
  kubectl() {
    local sub="" a
    for a in "$@"; do
      [[ $a == -* ]] || { sub=$a; break }
    done
    local -a passthrough=(exec attach port-forward proxy cp edit debug wait)
    # Streaming/interactive: must reach the terminal unbuffered.
    if (( ${passthrough[(I)$sub]} )); then
      command kubectl "$@"
      return
    fi
    case $sub in
      logs)
        if (( ${@[(I)-f]} || ${@[(I)--follow]} )); then command kubectl "$@"; return; fi ;;
      get)
        if (( ${@[(I)-w]} || ${@[(I)--watch]} || ${@[(I)--watch-only]} )); then command kubectl "$@"; return; fi ;;
      run|debug)
        if (( ${@[(I)-i]} || ${@[(I)-t]} || ${@[(I)-it]} || ${@[(I)--stdin]} || ${@[(I)--tty]} )); then
          command kubectl "$@"; return
        fi ;;
    esac
    command kubecolor "$@"
  }
  # Deferred: _comps[kubectl] is populated by the omz plugin, after this point.
  _box_kubecolor_compdef() {
    (( $+_comps[kubectl] )) && compdef kubecolor=kubectl 2>/dev/null
    add-zsh-hook -d precmd _box_kubecolor_compdef
  }
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd _box_kubecolor_compdef
fi

# GITTOP, recomputed on every cd. Some site bashrc setups export it per directory;
# without an equivalent hook zsh inherits whatever the launching bash had and it
# sticks, pointing at a repo you left long ago.
#
# Walked in pure zsh rather than forking git: identical output in every case tested
# (including a worktree nested in another repo), but 0.1ms against 6.5ms, and this
# runs on every cd. ${d:A} resolves symlinks to match git's physical path.
_box_set_gittop() {
  local d=$PWD
  while [[ -n $d && $d != / ]]; do
    if [[ -e $d/.git ]]; then
      export GITTOP=${d:A}
      return 0
    fi
    d=${d:h}
  done
  # Empty rather than unset, mirroring bash.
  export GITTOP=""
}
autoload -Uz add-zsh-hook
add-zsh-hook chpwd _box_set_gittop
_box_set_gittop   # seed for the directory the shell starts in

# ghq + gwq: one repo/worktree tree under $GHQ_ROOT.
if command -v gwq >/dev/null 2>&1; then
  source <(gwq completion zsh)
fi

if command -v ghq >/dev/null 2>&1 && command -v fzf >/dev/null 2>&1; then
  # fzf shows "<repo> <branch>"; the full path rides along as a hidden 2nd field.
  ghq-path() {
    local -A branch_of
    local p b
    while IFS=$'\t' read -r p b; do
      branch_of[$p]=$b
    done < <(gwq list --json -g 2>/dev/null | jq -r '.[] | [.path, .branch] | @tsv')

    local base label br
    for p in ${(f)"$(ghq list --full-path 2>/dev/null)"}; do
      br=${branch_of[$p]:-$(git -C "$p" symbolic-ref --short HEAD 2>/dev/null)}
      base=${p:t}
      label=${base%%=*}
      printf '%s %s\t%s\n' "$label" "${br:-detached}" "$p"
    done | fzf --delimiter '\t' --with-nth 1 \
               --preview 'git -C {2} log -1 --stat --color=always 2>/dev/null' \
               --preview-window 'right:60%' \
      | cut -f2
  }

  # Not `dev`: that name belongs to a CLI on some machines, and a function would
  # shadow it.
  wt() {
    local moveto
    moveto="$(ghq-path)" || return 1
    [[ -z "$moveto" ]] && return 1
    builtin cd "$moveto" || return 1
  }
fi

# A function, not an alias: it has to cd this shell to the path box prints.
if (( $+commands[box] )); then
  ,gwq() {
    local d
    d="$(box gwq "$@")" || return $?
    [[ -n "$d" ]] && cd "$d"
  }
fi

# fzf's zsh integration, sourced here rather than by home-manager.
#
# It snapshots $options and later restores it with `eval 'options=(...)'`.
# Assigning that array re-applies `privileged off`, and zsh implements that by
# calling setgid/setuid/setgroups -- which the user namespace denies when running
# as root, so every shell starts with two copies of
#
#   (eval):unsetopt:1: can't drop privileges; failed to set supplementary group
#   list: operation not permitted
#   (eval):1: can't change option: privileged
#
# Purely cosmetic: fzf loads fine either way. Filtered rather than blanket
# silenced, so any other fzf error still reaches the terminal. Only for root --
# an ordinary user never hits it.
if (( $+commands[fzf] )); then
  # Ctrl-R stays with the history manager; fzf keeps Ctrl-T and Alt-C.
  export FZF_CTRL_R_COMMAND=""
  if (( EUID == 0 )); then
    source <(fzf --zsh) 2> >(grep -v \
      -e "can't drop privileges" \
      -e "can't change option: privileged" >&2)
  else
    source <(fzf --zsh)
  fi
fi

zstyle ':completion:*' menu select
zstyle ':completion:*:descriptions' format '%d'

WORDCHARS=''
bindkey -e
