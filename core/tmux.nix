# gpakosz/.tmux, pinned as a flake input.
#
# programs.tmux is not used: .tmux.conf is a complete configuration, not a set of
# options, and letting home-manager generate a competing one gives you two sets of
# keybindings.
{ config, lib, pkgs, inputs, ... }:

{
  home.file.".tmux.conf".source = "${inputs.tmux-gpakosz}/.tmux.conf";

  # .tmux.conf.local is meant to be edited in place (prefix + e opens it and
  # re-sources it), so it is a writable copy rather than a store symlink. Seeded
  # only when absent -- overwriting would discard the edits it exists to hold.
  home.activation.tmuxLocalConf = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    _tmux_local="${config.home.homeDirectory}/.tmux.conf.local"
    if [ ! -e "$_tmux_local" ]; then
      run install -m 0644 ${inputs.tmux-local}/.tmux.conf.local "$_tmux_local"
    fi
  '';
}
