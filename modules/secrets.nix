{ ... }:

{
  meta = {
    summary = "Password store";
    apps = [
      { name = "pass"; pkg = "pass"; size = "~50M"; url = "https://www.passwordstore.org"; }
      { name = "sshpass"; pkg = "sshpass"; size = "~1M"; url = "https://sourceforge.net/projects/sshpass"; }
    ];
  };
}
