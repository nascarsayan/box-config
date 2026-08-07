{ ... }:

{
  meta = {
    summary = "Kubernetes CLI tooling";
    apps = [
      { name = "kubectl"; pkg = "kubectl"; size = "~55M"; url = "https://github.com/kubernetes/kubernetes/releases"; }
      { name = "kubecolor"; pkg = "kubecolor"; size = "~15M"; url = "https://github.com/kubecolor/kubecolor/releases"; }
      { name = "helm"; pkg = "kubernetes-helm"; size = "~80M"; url = "https://github.com/helm/helm/releases"; }
      { name = "k9s"; pkg = "k9s"; size = "~170M"; url = "https://github.com/derailed/k9s/releases"; }
      { name = "kubectx"; pkg = "kubectx"; size = "~5M"; url = "https://github.com/ahmetb/kubectx/releases"; }
      { name = "krew"; pkg = "krew"; size = "~10M"; url = "https://github.com/kubernetes-sigs/krew/releases"; }
      { name = "kubectl-tree"; pkg = "kubectl-tree"; size = "~10M"; url = "https://github.com/ahmetb/kubectl-tree/releases"; }
      { name = "stern"; pkg = "stern"; size = "~25M"; url = "https://github.com/stern/stern/releases"; }
    ];
  };
}
