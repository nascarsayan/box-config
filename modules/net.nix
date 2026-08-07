{ ... }:

{
  meta = {
    summary = "HTTP, transfer and JSON";
    apps = [
      { name = "xh"; pkg = "xh"; size = "~15M"; url = "https://github.com/ducaale/xh/releases"; }
      { name = "croc"; pkg = "croc"; size = "~25M"; url = "https://github.com/schollz/croc/releases"; }
      { name = "jnv"; pkg = "jnv"; size = "~10M"; url = "https://github.com/ynqa/jnv/releases"; }
    ];
  };
}
