{ ... }:

{
  meta = {
    summary = "Coding agents";
    apps = [
      # Off by default: an unattended install lands on machines nobody is
      # sitting at, and these are the largest things here.
      { name = "claude-code"; pkg = "claude-code"; size = "~270M"; default = false; url = "https://github.com/anthropics/claude-code/releases"; }
      { name = "codex"; pkg = "codex"; size = "~490M"; default = false; url = "https://github.com/openai/codex/releases"; }
    ];
  };
}
