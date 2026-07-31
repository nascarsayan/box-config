{ settings, ... }:

{
  home = {
    inherit (settings) username;

    # The sandbox, not the real home. This is what makes the dotfiles ordinary
    # home-manager output instead of a pile of ZDOTDIR/XDG_* overrides.
    homeDirectory = settings.sandboxHome;

    # home-manager semantics, not package versions.
    stateVersion = "25.05";
  };

  xdg.enable = true;
  programs.home-manager.enable = true;
}
