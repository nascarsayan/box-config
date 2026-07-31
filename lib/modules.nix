# Module discovery. Each file in ../modules returns { meta, config }.
#
# meta must not touch pkgs -- `box modules` reads every meta via `nix eval
# .#moduleMeta` and laziness keeps that from instantiating nixpkgs (~70ms).
{ lib }:

let
  dir = ../modules;

  names = lib.pipe (builtins.readDir dir) [
    (lib.filterAttrs (n: type: type == "regular" && lib.hasSuffix ".nix" n))
    builtins.attrNames
    (map (lib.removeSuffix ".nix"))
    (lib.filter (n: !lib.hasPrefix "_" n)) # _foo.nix = helper, not a module
  ];

  load = name: import (dir + "/${name}.nix");

  purityError = "a module's `meta` may not reference pkgs or settings; move it to `config`";
  metaOf = name: ((load name) { pkgs = throw purityError; inherit lib; settings = { }; }).meta;
in
{
  inherit names;

  meta = lib.genAttrs names metaOf;
  defaults = lib.filter (n: (metaOf n).default or false) names;

  # Unknown names throw rather than no-op: a typo should say so, not silently
  # leave a tool uninstalled and look like a nixpkgs problem.
  modulesFor = { enabled, pkgs, settings }:
    let unknown = lib.subtractLists names enabled; in
    lib.throwIf (unknown != [ ])
      "unknown module(s): ${lib.concatStringsSep ", " unknown}; available: ${lib.concatStringsSep ", " names}"
      (map (n: ((load n) { inherit pkgs lib settings; }).config)
        (lib.filter (n: lib.elem n enabled) names));
}
