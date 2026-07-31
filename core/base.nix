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
    unzip
    xz

    # data
    jq
    yq-go

    # shell integrations that also need to be on PATH
    fzf
    zoxide
    atuin
    mise

    # Pinned, not inherited: the host PATH is appended, so omitting these would mix
    # a nix zsh with the distro's coreutils.
    coreutils
    gnused
    gnugrep
    gawk
    findutils
    diffutils
    less
    which
    file
    curl
    openssh
    util-linux
  ]
  # ,gwq / ,rv / ,gcw
  ++ (with boxPkgs; [ box-gwq-review box-gwq-gc box-review-open ])
  ++ [ hmPackage ];

  # nix is deliberately absent: box init puts it in ~/.nix-profile and it survives
  # activation. Listing it here makes a *fresh* profile unbuildable -- both entries
  # own lib/systemd/system/nix-daemon.socket.
}
