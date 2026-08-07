{
  description = "Declarative rootless dev sandbox, applied by the box CLI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Config repos, not flakes. Pinned so the revision lives in flake.lock.
    tmux-gpakosz = { url = "github:gpakosz/.tmux"; flake = false; };
    tmux-local = { url = "github:nascarsayan/.tmux.local"; flake = false; };
    kubectl-aliases = { url = "github:ahmetb/kubectl-aliases"; flake = false; };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      inherit (nixpkgs) lib;

      moduleSet = import ./lib/modules.nix { inherit lib; };

      # This machine's answers, gitignored so the tracked tree stays a clean,
      # contributable library. Only `path:` flakes see untracked files, which is why
      # box never applies from a github: ref -- through one, these would be invisible
      # and the defaults below would silently win.
      #
      # JSON is what box reads and rewrites; local.nix is merged on top for anything
      # needing a real expression.
      localJSON =
        if builtins.pathExists ./local.json
        then builtins.fromJSON (builtins.readFile ./local.json)
        else { };
      localNix = if builtins.pathExists ./local.nix then import ./local.nix else { };
      local = localJSON // localNix;

      defaults = {
        system = "x86_64-linux";
        username = "nixbox";
        realHome = "/home/nixbox";
        sandboxHome = "/home/nixbox/sandbox";
        confDir = "/home/nixbox/.config/box";
        ghqRoot = "/home/nixbox/ghq";
        ghConfigDir = "/home/nixbox/.config/gh";
        tmuxSocket = "box";
        git = { userName = ""; userEmail = ""; };
        # Resolved by box, so nix never stats outside the flake (keeps eval pure).
        passthrough = [ ];
        sessionVariables = { };
        apps = moduleSet.defaults;
        modules = null;
      };

      # `or null` guards: local.json is hand-editable and a JSON null for a list
      # otherwise surfaces as "expected a list but found null" from deep inside
      # lib.subtractLists, with nothing pointing at the actual cause.
      orDefault = name: if (local.${name} or null) == null then defaults.${name} else local.${name};

      # Selection is per app. A local.json written before the split has only
      # `modules`, so expand it rather than silently installing the default set
      # over someone's choices -- an upgrade must not change what is installed.
      selectedApps =
        if (local.apps or null) != null then local.apps
        else if (local.modules or null) != null then moduleSet.appsForModules local.modules
        else defaults.apps;

      settings = defaults // local // {
        git = defaults.git // (local.git or { });
        apps = selectedApps;
        passthrough = orDefault "passthrough";
        sessionVariables = orDefault "sessionVariables";
      };

      inherit (settings) system;

      pkgs = import nixpkgs {
        inherit system;
        # claude-code is unfree.
        config.allowUnfree = true;
      };

      hmPackage = home-manager.packages.${system}.home-manager;
      boxPkgs = import ./pkgs { inherit pkgs; };
    in
    {
      # Read by `box modules`; cheap because no module's `config` is forced.
      moduleMeta = moduleSet.meta;
      moduleDefaults = moduleSet.defaults;
      moduleNames = moduleSet.names;
      appNames = moduleSet.appNames;
      appAutomatic = moduleSet.automatic;

      # Also usable directly: home-manager switch --flake .#sandbox
      homeConfigurations.sandbox = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit inputs settings boxPkgs hmPackage; };
        modules = [
          ./core/base.nix
          ./core/env.nix
          ./core/zsh.nix
          ./core/tmux.nix
          ./core/git.nix
          ./core/tools.nix
          ./core/real-home.nix
          ./core/home.nix
        ]
        ++ [{ home.packages = moduleSet.packagesFor { inherit pkgs; enabled = settings.apps; }; }]
        ++ moduleSet.configsFor {
          inherit pkgs settings;
          enabled = settings.apps;
        };
      };

      packages.${system} = boxPkgs;
      formatter.${system} = pkgs.nixpkgs-fmt;
    };
}
