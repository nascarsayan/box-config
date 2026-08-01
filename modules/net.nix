{ pkgs, ... }:

{
  meta = {
    summary = "HTTP, transfer and JSON";
    size = "~180M";
    apps = [
      { name = "xh"; url = "https://github.com/ducaale/xh/releases"; }
      { name = "croc"; url = "https://github.com/schollz/croc/releases"; }
      { name = "jnv"; url = "https://github.com/ynqa/jnv/releases"; }
    ];
  };

  config.home.packages = with pkgs; [ xh croc jnv ];
}
