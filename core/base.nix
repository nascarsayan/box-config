# Always-on tools. Everything optional is in ../modules, toggled by `box modules`.
{ pkgs, boxPkgs, hmPackage, ... }:

{
  home.packages = with pkgs; [
    # shell + multiplexer
    zsh
    tmux

    # $EDITOR is hx, so not optional.
    helix

    # git
    git
    gh
    delta
    ghq
    gwq
    git-extras

    # search and listing
    ripgrep
    fd
    eza
    bat
    broot

    # data
    jq
    yq-go

    # shell integrations that also need to be on PATH
    fzf
    zoxide
    atuin
    mise

    # Base userland (coreutils, sed, grep, awk, find, diff, less, which, file,
    # curl, unzip, xz, util-linux, ssh) comes from the host PATH, which box appends.
    # Never add openssh: nixpkgs' upstream ssh reads the host /etc/ssh/ssh_config,
    # and RHEL's crypto-policies include sets GSSAPIKexAlgorithms, a distro-patch
    # option upstream rejects as fatal.
  ]
  # ,gwq / ,rv / ,gcw
  ++ (with boxPkgs; [ box-gwq-review box-gwq-gc box-review-open ])
  ++ [ hmPackage ];

  # nix is deliberately absent: box init puts it in ~/.nix-profile and it survives
  # activation. Listing it here makes a *fresh* profile unbuildable -- both entries
  # own lib/systemd/system/nix-daemon.socket.
}
