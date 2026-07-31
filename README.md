# box-config

The nix configuration that [`box`](https://github.com/nascarsayan/box) applies. A
rootless dev sandbox: `nix-user-chroot` + `home-manager`, no root anywhere.

You do not clone this by hand — `box init` does it, to `~/.config/box`.

```sh
curl -fsSL https://raw.githubusercontent.com/nascarsayan/box/main/install.sh | sh -
```

## Layout

```
flake.nix          inputs, settings resolution, homeConfigurations.sandbox
lib/modules.nix    module discovery: reads modules/ and exposes moduleMeta
modules/*.nix      optional features, one file each   <- tracked, contributable
core/*.nix         always-on config (shell, git, tmux, tool integrations)
zsh/*.zsh          zsh fragments, read with builtins.readFile
pkgs/              the ,gwq / ,rv / ,gcw helpers
local.json         your paths and module selection    <- gitignored
local.nix          optional nix overrides             <- gitignored
```

The tracked/untracked split is the point. Everything that describes *what a module
is* is tracked, so a change you make shows up as an ordinary `git diff` and can be
sent upstream. Everything that describes *your machine* is gitignored, so it never
appears in one.

## Adding a module

One file. Nothing else needs to know it exists — not `flake.nix`, not the `box` CLI.

```nix
# modules/rust.nix
{ pkgs, ... }:

{
  meta = {
    summary = "Rust toolchain";
    description = ''
      rustc, cargo and rust-analyzer.
    '';
    size = "~1.1G";
    default = false;
  };

  config.home.packages = with pkgs; [ rustc cargo rust-analyzer ];
}
```

Then `box modules` lists it.

`meta` **must not reference `pkgs`**, and `lib/modules.nix` enforces that by passing
a `throw` in its place. That is what makes `box modules` fast: nix is lazy, so
reading every module's metadata never forces its `config`, and nixpkgs is not
instantiated just to print a list of descriptions. It takes about 70ms.

## Configuration

`box init` writes `local.json`:

```json
{
  "username": "you",
  "realHome": "/home/you",
  "sandboxHome": "/home/you/sandbox",
  "ghqRoot": "/home/you/ghq",
  "git": { "userName": "You", "userEmail": "you@example.com" },
  "passthrough": ["ws", ".ssh", ".kube"],
  "modules": ["kubernetes", "files"]
}
```

JSON rather than nix so the CLI can rewrite it without generating nix source. For
anything that genuinely needs an expression, add a `local.nix` beside it; it is
merged on top.

Everything absent from `local.json` falls back to the portable defaults in
`flake.nix`, which name no user, host or absolute path.

## Why `$HOME` is repointed

Inside the sandbox, `HOME` is the sandbox directory. That single decision is what
lets this be ordinary home-manager output — `~/.zshrc`, `~/.tmux.conf`,
`~/.gitconfig` — instead of a pile of `ZDOTDIR`/`XDG_*`/`TMUX_CONF` overrides whose
only purpose was keeping those files out of the real home.

`core/real-home.nix` symlinks back what must stay shared: the workspace tree, ssh
keys, kube contexts, agent state, and gh's token directory. Those use
`mkOutOfStoreSymlink`, never `source` — a plain `source` would copy an ssh private
key into a world-readable store path.

`passthrough` is resolved by `box init`, which checks what exists, rather than by
`builtins.pathExists` here. That keeps evaluation pure: nix never stats a path
outside the flake, so nothing needs `--impure`.

## Gotchas

**`.tmux.conf.local` is a writable copy, not a store symlink.** Upstream designs it
to be edited in place — `prefix + e` opens it in `$EDITOR` and re-sources it — so a
read-only symlink would break that. It is seeded from the pinned input only when
absent and never overwritten, because clobbering it would discard exactly the local
edits it exists to hold.

**tmux runs on its own socket.** `TMUX_TMPDIR` is `<sandbox>/run`, so the sandbox's
server is separate from any other. `,,` in one does not attach to the other.

**Completion staleness is handled by oh-my-zsh, not by hand.** It stamps
`#omz fpath:` into the dump and deletes it whenever `fpath` changes; under nix every
`fpath` entry is a store path, so any package change invalidates the dump exactly
and immediately.

## Applying by hand

`box` is a convenience, not a requirement:

```sh
cd ~/.config/box
home-manager switch --flake .#sandbox
```

Must be a `path:` flake, though — see the note in `flake.nix` about why a `github:`
ref would silently ignore `local.json`.
