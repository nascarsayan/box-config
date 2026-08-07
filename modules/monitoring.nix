{ ... }:

{
  meta = {
    summary = "Process and system inspection";
    apps = [
      { name = "btop"; pkg = "btop"; size = "~15M"; url = "https://github.com/aristocratos/btop/releases"; }
      { name = "procs"; pkg = "procs"; size = "~10M"; url = "https://github.com/dalance/procs/releases"; }
      { name = "sysz"; pkg = "sysz"; size = "~1M"; url = "https://github.com/joehillen/sysz/releases"; }
    ];
  };
}
