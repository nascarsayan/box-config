# zsh. No plugin manager: zinit fetched 14 things over the network at first prompt
# and symlinked completions by absolute path, which silently broke them whenever the
# sandbox moved. Each is a package or a pinned input now.
{ pkgs, lib, config, inputs, settings, ... }:

{
  programs.zsh = {
    enable = true;

    # Pinned: the default flips at stateVersion 26.05, and moving ZDOTDIR would
    # strand the history file.
    dotDir = config.home.homeDirectory;

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    history = {
      path = "${settings.sandboxHome}/.zsh_history";
      size = 10000;
      save = 10000;
      share = true;
      append = true;
      expireDuplicatesFirst = true;
      ignoreDups = true;
      findNoDups = true;
      # HIST_REDUCE_BLANKS
      extended = false;
    };

    # setopt HIST_REDUCE_BLANKS has no home-manager option.
    localVariables = { };

    oh-my-zsh = {
      enable = true;
      # No theme: powerlevel10k is a plugin below.
      plugins = [
        "git"
        "sudo"
        "colored-man-pages"
        "kubectl"
        "docker"
        "docker-compose"
        "helm"
        "vscode"
        "git-extras"
      ];

      # Emitted before `source $ZSH/oh-my-zsh.sh`, the only window where these work.
      #
      # No completionInit: home-manager omits it when oh-my-zsh is enabled, because
      # omz runs compinit itself -- and does it better than the hand-rolled 24h rule
      # this used to carry. omz stamps `#omz fpath:` into the dump and deletes it
      # when fpath changes; under nix every fpath entry is a store path, so any
      # package change invalidates it exactly.
      extraConfig = ''
        # Out of $HOME; omz defaults to ~/.zcompdump-$HOST-$ZSH_VERSION.
        ZSH_COMPDUMP="${config.xdg.cacheHome}/zsh/zcompdump-''${HOST}-''${ZSH_VERSION}"
        [[ -d ''${ZSH_COMPDUMP:h} ]] || mkdir -p ''${ZSH_COMPDUMP:h}

        # compaudit cannot resolve gids inside the user namespace and prints
        # `unknown group` on every compinit. Nothing to audit: fpath is the store.
        ZSH_DISABLE_COMPFIX=true
      '';
    };

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      # Sourcing the p10k config as a plugin gets the ordering right for free.
      {
        name = "p10k-config";
        src = ../zsh;
        file = "p10k.zsh";
      }
      {
        name = "zsh-completions";
        src = pkgs.zsh-completions;
        file = "share/zsh-completions/zsh-completions.plugin.zsh";
      }
    ];

    # .zshenv: runs before /etc/zshrc, which is where the LD_LIBRARY_PATH strip
    # has to happen. See the file for why.
    envExtra = builtins.readFile ../zsh/zshenv-body.zsh;

    shellAliases = {
      # box dispatches directly when already inside the sandbox.
      ",," = "box tmux";
      ",rv" = "box review";
      ",gcw" = "box gc";
      # ,gwq is a function (needs to cd this shell) -- see zshrc-body.zsh.
    };

    initContent = lib.mkMerge [
      # Must precede anything that writes to the terminal.
      (lib.mkBefore (builtins.readFile ../zsh/instant-prompt.zsh))

      # Config is checked in, so the wizard must never trigger.
      (lib.mkBefore ''
        export POWERLEVEL10K_DISABLE_CONFIGURATION_WIZARD=1
        setopt HIST_REDUCE_BLANKS
      '')

      (lib.mkOrder 1500 (builtins.readFile ../zsh/zshrc-body.zsh))
    ];
  };

  # Pinned input rather than a raw URL fetched at shell startup.
  xdg.configFile."box/kubectl_aliases".source =
    "${inputs.kubectl-aliases}/.kubectl_aliases";
}
