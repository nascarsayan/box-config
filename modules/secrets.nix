{ pkgs, ... }:

{
  meta = {
    summary = "Password store";
    description = ''
      pass and sshpass. Enabling this makes the `sshp` helper appear in zsh,
      which reads an ssh password from `pass`. Point it at your entry with
      $BOX_SSH_PASS_ENTRY; it defaults to `ssh/default`.

      Nothing here manages your GPG keys or the store itself; ~/.gnupg and the
      store stay outside the sandbox.
    '';
    size = "~90M";
    default = false;
  };

  config.home.packages = with pkgs; [ pass sshpass ];
}
