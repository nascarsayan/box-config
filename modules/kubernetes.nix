{ pkgs, ... }:

{
  meta = {
    summary = "Kubernetes CLI tooling";
    size = "~1.2G";
    apps = [
      { name = "kubectl"; url = "https://github.com/kubernetes/kubernetes/releases"; }
      { name = "kubecolor"; url = "https://github.com/kubecolor/kubecolor/releases"; }
      { name = "helm"; url = "https://github.com/helm/helm/releases"; }
      { name = "k9s"; url = "https://github.com/derailed/k9s/releases"; }
      { name = "kubectx"; url = "https://github.com/ahmetb/kubectx/releases"; }
      { name = "krew"; url = "https://github.com/kubernetes-sigs/krew/releases"; }
      { name = "kubectl-tree"; url = "https://github.com/ahmetb/kubectl-tree/releases"; }
      { name = "stern"; url = "https://github.com/stern/stern/releases"; }
    ];
  };

  config.home.packages = with pkgs; [ kubectl kubecolor kubernetes-helm k9s kubectx krew kubectl-tree stern ];
}
