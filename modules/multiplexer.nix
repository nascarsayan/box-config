{ pkgs, ... }:

{
  meta = {
    summary = "Terminal multiplexer, beside tmux";
    size = "~90M";
    # Off unless asked for: tmux is already configured in core, so this is a
    # second multiplexer for people who want one, not a default.
    default = false;
    apps = [
      { name = "zellij"; url = "https://github.com/zellij-org/zellij/releases"; }
    ];
  };

  config.home.packages = with pkgs; [ zellij ];
}
