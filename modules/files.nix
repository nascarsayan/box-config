{ pkgs, ... }:

{
  meta = {
    summary = "File managers and archives";
    size = "~250M";
    apps = [
      { name = "yazi"; url = "https://github.com/sxyazi/yazi/releases"; }
      { name = "duf"; url = "https://github.com/muesli/duf/releases"; }
      { name = "tre"; url = "https://github.com/dduan/tre/releases"; }
      { name = "7z"; url = "https://github.com/p7zip-project/p7zip/releases"; }
      { name = "7zz"; url = "https://github.com/ip7z/7zip/releases"; }
    ];
  };

  config.home.packages = with pkgs; [ yazi duf tre-command p7zip _7zz ];
}
