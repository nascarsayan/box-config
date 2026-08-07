{ pkgs, ... }:

{
  meta = {
    summary = "Coding agents";
    size = "~750M";
    # Off unless asked for: an unattended install lands on machines nobody is
    # sitting at, and coding agents are the largest thing here by far.
    default = false;
    apps = [
      { name = "claude-code"; url = "https://github.com/anthropics/claude-code/releases"; }
      { name = "codex"; url = "https://github.com/openai/codex/releases"; }
    ];
  };

  config.home.packages = with pkgs; [ claude-code codex ];
}
