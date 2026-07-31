# git.
{ pkgs, settings, ... }:

{
  programs.git = {
    enable = true;

    lfs.enable = true;

    ignores = [
      ".claude/"
      "core.[0-9]*"
      ".local/"
      "/.tmp/"
    ];

    settings = {
      user = {
        name = settings.git.userName;
        email = settings.git.userEmail;
      };

      pull.rebase = true;
      push.default = "simple";

      # Noticeably faster log/blame on large repos.
      core.commitGraph = true;
      gc.writeCommitGraph = true;

      ghq.root = settings.ghqRoot;

      init.defaultBranch = "main";

      # Empty `helper =` first, to reset any inherited system-wide helper.
      # GH_CONFIG_DIR inline, not from the environment: git invokes the helper from
      # contexts that never sourced the sandbox profile (an IDE's `git fetch`).
      credential."https://github.com".helper = [
        ""
        "!GH_CONFIG_DIR=${settings.ghConfigDir} ${pkgs.gh}/bin/gh auth git-credential"
      ];
      credential."https://gist.github.com".helper = [
        ""
        "!GH_CONFIG_DIR=${settings.ghConfigDir} ${pkgs.gh}/bin/gh auth git-credential"
      ];
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options.navigate = true;
  };
}
