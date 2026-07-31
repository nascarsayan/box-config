# Symlinks from the sandbox home back to the real one, for state that must not be
# duplicated per sandbox.
#
# mkOutOfStoreSymlink, never `source`: `source` would copy an ssh key into a
# world-readable store path. passthrough is pre-filtered by box, so nix never stats
# outside the flake and nothing needs --impure.
{ config, lib, settings, ... }:

let linkOut = config.lib.file.mkOutOfStoreSymlink; in
{
  home.file = lib.listToAttrs (map
    (p: { name = p; value.source = linkOut "${settings.realHome}/${p}"; })
    settings.passthrough);

  # hosts.yml holds a token: outside the store, and survives a rebuild.
  xdg.configFile."gh".source = linkOut settings.ghConfigDir;
}
