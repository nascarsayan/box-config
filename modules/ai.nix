{ pkgs, ... }:

{
  meta = {
    summary = "Coding agents";
    size = "~2.2G";
    apps = [
      { name = "claude-code"; url = "https://github.com/anthropics/claude-code/releases"; }
      { name = "codex"; url = "https://github.com/openai/codex/releases"; }
      { name = "crush"; url = "https://github.com/charmbracelet/crush/releases"; }
    ];
  };

  config.home.packages = with pkgs; [ claude-code codex crush ];
}
