{ pkgs, ... }:

{
  meta = {
    summary = "Terminal multiplexer, beside tmux";
    size = "~90M";
    apps = [
      { name = "zellij"; url = "https://github.com/zellij-org/zellij/releases"; }
    ];
  };

  config.home.packages = with pkgs; [ zellij ];
}
