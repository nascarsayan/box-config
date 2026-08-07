# Module discovery. Each file in ../modules returns { meta, config? }.
#
# meta must not touch pkgs -- `box modules` reads every meta via `nix eval
# .#moduleMeta` and laziness keeps that from instantiating nixpkgs (~70ms).
#
# Selection is per app, not per module. A module is a heading: it groups apps
# in the picker and gives them a shared summary. What actually gets installed
# is the set of app names, because "I want kubectl but not k9s" is a normal
# thing to want and grouping should not stand in the way of it.
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
  loadPure = name: (load name) { pkgs = throw purityError; inherit lib; settings = { }; };
  metaOf = name: (loadPure name).meta;

  appsOf = name: (metaOf name).apps or [ ];

  # Every app across every module, flattened. Names are unique cluster-wide --
  # two modules claiming the same app name is a mistake, not a merge.
  allApps = lib.concatMap (m: map (a: a // { module = m; }) (appsOf m)) names;

  appNames = map (a: a.name) allApps;

  duplicates = lib.subtractLists (lib.unique appNames) appNames;

  byName = lib.listToAttrs (map (a: lib.nameValuePair a.name a) allApps);
in
lib.throwIf (duplicates != [ ])
  "app name(s) declared by more than one module: ${lib.concatStringsSep ", " (lib.unique duplicates)}"
{
  inherit names;

  meta = lib.genAttrs names metaOf;

  inherit allApps appNames;

  # Interactive: everything preselected. Someone is watching, sizes are on
  # screen, and unticking one is a keystroke.
  defaults = appNames;

  # Unattended (`--yes`, `curl | sh`): only apps that did not opt out with
  # `default = false`. Nobody is there to decline, so the heavyweights ask.
  # An app declares this itself; box knows nothing about what any app is.
  automatic = map (a: a.name) (lib.filter (a: a.default or true) allApps);

  # Apps belonging to the named modules -- what `--modules kubernetes` means
  # now that selection is per app.
  appsForModules = mods: map (a: a.name) (lib.filter (a: lib.elem a.module mods) allApps);

  # Unknown names throw rather than no-op: a typo should say so, not silently
  # leave a tool uninstalled and look like a nixpkgs problem.
  packagesFor = { enabled, pkgs }:
    let unknown = lib.subtractLists appNames enabled; in
    lib.throwIf (unknown != [ ])
      "unknown app(s): ${lib.concatStringsSep ", " unknown}; available: ${lib.concatStringsSep ", " appNames}"
      (map (n: pkgs.${byName.${n}.pkg}) (lib.filter (n: lib.elem n enabled) appNames));

  # A module may still carry configuration beyond packages (none do yet). It
  # applies when any of its apps is enabled.
  configsFor = { enabled, pkgs, settings }:
    let
      live = m: lib.any (a: lib.elem a.name enabled) (appsOf m);
      cfg = m: ((load m) { inherit pkgs lib settings; }).config or null;
    in
    lib.filter (c: c != null) (map cfg (lib.filter live names));
}
