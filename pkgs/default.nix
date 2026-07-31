# The ,gwq / ,rv / ,gcw helpers.
#
# Kept as shell: this is logic debugged against real merged, squashed,
# deleted-branch and cross-fork PRs. runtimeInputs bakes in git/gh/jq/gwq so the
# scripts no longer have to guess where those live.
{ pkgs }:

let
  inherit (pkgs) lib;

  stripShebang = text:
    let lines = lib.splitString "\n" text; in
    lib.concatStringsSep "\n"
      (if lib.hasPrefix "#!" (lib.head lines) then lib.tail lines else lines);

  mkHelper = name: pkgs.writeShellApplication {
    inherit name;
    runtimeInputs = with pkgs; [
      git gh jq gwq coreutils gnugrep gnused gawk findutils util-linux
    ];
    text = stripShebang (builtins.readFile (./. + "/${name}.sh"));
    # Default also fails on style/info findings; these are held to -S warning.
    checkPhase = ''
      ${pkgs.stdenv.shell} -n "$target"
      ${pkgs.shellcheck}/bin/shellcheck -S warning "$target"
    '';
  };
in
{
  box-gwq-review = mkHelper "box-gwq-review";
  box-gwq-gc = mkHelper "box-gwq-gc";
  # No `code` in runtimeInputs: VS Code's remote CLI is a host install, and resolves
  # because writeShellApplication appends the inherited PATH.
  box-review-open = mkHelper "box-review-open";
}
