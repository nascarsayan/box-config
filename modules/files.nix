{ ... }:

{
  meta = {
    summary = "File managers and archives";
    apps = [
      # yazi pulls ffmpeg, which pulls clang and llvm: 1.36G, a third of a
      # default install, for a TUI file manager. Worth having, not worth
      # putting on every machine without being asked.
      { name = "yazi"; pkg = "yazi"; size = "~1.4G"; default = false; url = "https://github.com/sxyazi/yazi/releases"; }
      { name = "duf"; pkg = "duf"; size = "~10M"; url = "https://github.com/muesli/duf/releases"; }
      { name = "tre"; pkg = "tre-command"; size = "~5M"; url = "https://github.com/dduan/tre/releases"; }
      { name = "7z"; pkg = "p7zip"; size = "~15M"; url = "https://github.com/p7zip-project/p7zip/releases"; }
      { name = "7zz"; pkg = "_7zz"; size = "~5M"; url = "https://github.com/ip7z/7zip/releases"; }
    ];
  };
}
