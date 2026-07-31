{ pkgs, ... }:

{
  meta = {
    summary = "File managers and archive tools";
    description = ''
      yazi (TUI file manager), duf for disk usage, tre for trees, and the 7-Zip
      pair -- p7zip for the classic `7z` and _7zz for the newer standalone build
      the imperative installer fetched separately.
    '';
    size = "~250M";
    default = true;
  };

  config.home.packages = with pkgs; [ yazi duf tre-command p7zip _7zz ];
}
