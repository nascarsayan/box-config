# Per-tool config. Each programs.<x>.enable replaces both an install_<x> function
# and an `eval "$(<x> init zsh)"` at every prompt -- the snippet is generated at
# build time now.
{ pkgs, config, settings, ... }:

{
  # --- shell integrations ---------------------------------------------------

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --exclude .git";
    defaultOptions = [ "--height 40%" "--border" ];

    # fzf and atuin both want Ctrl-R; atuin gets it, fzf keeps Ctrl-T and Alt-C.
    historyWidget.zsh.command = "";
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    # Up-arrow stays zsh's own history search.
    flags = [ "--disable-up-arrow" ];
  };

  programs.mise = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.broot = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.bat.enable = true;

  programs.eza = {
    enable = true;
    # The ls alias is in zsh.nix; this would define a competing one.
    enableZshIntegration = false;
  };

  # --- editor ---------------------------------------------------------------

  programs.helix = {
    enable = true;
    settings = {
      theme = "catppuccin_macchiato";
      editor = {
        line-number = "relative";
        mouse = true;
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        file-picker.hidden = false;
      };
    };
  };

  # --- worktree manager -----------------------------------------------------

  # launch_shell = false lets `gwq cd` and ,gwq cd the calling shell.
  xdg.configFile."gwq/config.toml".text = ''
    [cd]
    launch_shell = false

    [naming]
    template = '{{.Host}}/{{.Owner}}/{{.Repository}}={{.Branch}}'

    [worktree]
    basedir = '${settings.ghqRoot}'
  '';

  # --- nix itself -----------------------------------------------------------

  # box passes --extra-experimental-features for the first apply; from then on this
  # is what keeps flakes on -- so nix.conf is a store symlink, not hand-editable.
  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      warn-dirty = false;
      # Single-user install: no daemon, no build-user group.
      build-users-group = "";
      auto-optimise-store = true;
    };
  };

  home.sessionVariables.NIX_BUILD_TOP = "${settings.sandboxHome}/tmp";
}
