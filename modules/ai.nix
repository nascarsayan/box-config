{ pkgs, ... }:

{
  meta = {
    summary = "Coding agents";
    description = ''
      Claude Code, OpenAI Codex and Charm's Crush.

      The single largest module. It replaces the imperative chain the bash
      installer needed for Claude Code alone -- n-install, then Node, then bun,
      then `bun i -g @anthropic-ai/claude-code`, plus a libatomic.so.1 workaround
      when the host lacked it.

      Agent state (~/.claude and friends) is symlinked back to the real home, so
      credentials and history survive a sandbox rebuild.
    '';
    size = "~2.2G";
    default = true;
  };

  config = {
    home.packages = with pkgs; [
      claude-code
      codex
      crush
    ];
  };
}
