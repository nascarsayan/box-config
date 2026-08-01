{ pkgs, ... }:

{
  meta = {
    summary = "Password store";
    size = "~90M";
    apps = [
      { name = "pass"; url = "https://www.passwordstore.org"; }
      { name = "sshpass"; url = "https://sourceforge.net/projects/sshpass"; }
    ];
  };

  config.home.packages = with pkgs; [ pass sshpass ];
}
