{ pkgs, ... }:

{
  meta = {
    summary = "zellij, alongside tmux";
    description = ''
      zellij as an alternative multiplexer. tmux is part of the core config and
      always present -- this is purely additive, for when you want panes without
      tmux's keybindings.
    '';
    size = "~90M";
    default = false;
  };

  config.home.packages = [ pkgs.zellij ];
}
