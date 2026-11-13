# Environment. Lands in hm-session-vars.sh, which .zshrc and box both source.
# Anything that must run before /etc/zshrc goes in programs.zsh.envExtra instead.
{ config, settings, ... }:

{
  # settings.sessionVariables merged first so local.json can add site-specific vars.
  home.sessionVariables = settings.sessionVariables // {
    SANDBOX_HOME = settings.sandboxHome;

    SANDBOX_REAL_HOME = settings.realHome;

    SANDBOX_CONF_DIR = settings.confDir;

    EDITOR = "hx";
    VISUAL = "hx";
    PAGER = "less";

    # $HOME is the sandbox, which would move Python's per-user site-packages
    # off the real home and drop host .pth files with it (cscfg's
    # cluster_deployment.pth adds its venv to sys.path).
    PYTHONUSERBASE = "${settings.realHome}/.local";

    # Symlinked out (real-home.nix) so the token survives rebuilds.
    GH_CONFIG_DIR = "${config.xdg.configHome}/gh";

    KREW_ROOT = "${config.xdg.dataHome}/krew";
    KREW_HOME = "${config.xdg.dataHome}/krew";

    BUN_INSTALL = "${settings.sandboxHome}/.bun";

    GHQ_ROOT = settings.ghqRoot;

    TMUX_SOCKET_NAME = settings.tmuxSocket;
    TMUX_CONF = "${settings.sandboxHome}/.tmux.conf";
    TMUX_CONF_LOCAL = "${settings.sandboxHome}/.tmux.conf.local";

    # /tmp is small and shared; nix builds will fill it.
    TMPDIR = "${settings.sandboxHome}/tmp";
  };

  home.sessionPath = [
    # box, copied out of the store so it also runs outside the chroot.
    "${settings.sandboxHome}/bin"
    "${config.xdg.dataHome}/krew/bin"
    "${settings.sandboxHome}/.bun/bin"
  ];

}
