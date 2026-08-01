{ pkgs, ... }:

{
  meta = {
    summary = "Process and system inspection";
    size = "~120M";
    apps = [
      { name = "btop"; url = "https://github.com/aristocratos/btop/releases"; }
      { name = "procs"; url = "https://github.com/dalance/procs/releases"; }
      { name = "sysz"; url = "https://github.com/joehillen/sysz/releases"; }
    ];
  };

  config.home.packages = with pkgs; [ btop procs sysz ];
}
