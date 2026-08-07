{ ... }:

{
  meta = {
    summary = "Terminal multiplexer, beside tmux";
    apps = [
      # tmux is already set up in core, so this is a second multiplexer for
      # people who want one rather than something every machine needs.
      { name = "zellij"; pkg = "zellij"; size = "~90M"; default = false; url = "https://github.com/zellij-org/zellij/releases"; }
    ];
  };
}
