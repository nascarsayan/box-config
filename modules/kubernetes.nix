{ pkgs, ... }:

{
  meta = {
    summary = "Kubernetes CLI tooling";
    description = ''
      kubectl plus the tools that make it usable: kubecolor for coloured output,
      helm, k9s, kubectx, and the two krew plugins worth having (tree, stern).

      Enabling this also activates the kubectl -> kubecolor routing in zsh, which
      dispatches per subcommand so that exec/attach/port-forward/logs -f keep
      streaming unbuffered.
    '';
    size = "~1.2G";
    default = true;
  };

  config = {
    home.packages = with pkgs; [
      kubectl
      kubecolor
      kubernetes-helm
      k9s
      kubectx
      # krew itself is kept for installing plugins beyond these two, which are
      # the only ones the imperative installer ever bootstrapped it for.
      krew
      kubectl-tree
      stern
    ];
  };
}
