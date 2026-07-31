{ pkgs, ... }:

{
  meta = {
    summary = "HTTP and file transfer";
    description = ''
      xh for HTTP requests (a faster httpie), croc for sending files between
      machines, and jnv for interactively exploring JSON with jq expressions.
    '';
    size = "~180M";
    default = true;
  };

  config.home.packages = with pkgs; [ xh croc jnv ];
}
