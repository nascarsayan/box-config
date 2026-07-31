# Powerlevel10k instant prompt. Must come before anything that writes to the
# terminal, which is why this is spliced in with lib.mkBefore rather than sitting
# with the rest of the config.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
