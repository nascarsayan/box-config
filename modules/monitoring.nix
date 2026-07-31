{ pkgs, ... }:

{
  meta = {
    summary = "Process and system inspection";
    description = ''
      btop instead of top, procs instead of ps, and sysz as a systemd TUI.
    '';
    size = "~120M";
    default = true;
  };

  config.home.packages = with pkgs; [ btop procs sysz ];
}
