# box-config

> **Retired (2026-11-19).** No longer maintained; this repository is archived.
> Its contents were folded into a private tool.

Shell configuration templates for two installers:

- [`init-sh`](https://github.com/nascarsayan/init-sh) renders them on a macOS or Linux host.
- The `dev` CLI renders them for its per-node zsh on remote machines.

```
portable/*.j2   templates (zshrc, zshenv, gwq config)
zsh/*.zsh       fragments the templates include
```

The templates use a small Jinja subset: `{{ var }}`, `{{ "literal" }}`,
`{% include "path" %}` and `{% if var %}...{% endif %}`. Machine-specific
additions go in `~/.config/zsh/zshrc.d/*.zsh` and `zshenv.d/*.zsh`.

The Nix configuration that the retired `box` sandbox used was removed; it is
in the git history.
