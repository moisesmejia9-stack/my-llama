resource "null_resource" "eks_destroy_cleanup" {
  triggers = {
    cluster_name = module.eks.cluster_name
    region       = local.region
  }

  depends_on = [
    module.eks,
    module.eks_blueprints_addons,
    module.karpenter,
  ]

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      set -euo pipefail

      if ! command -v aws >/dev/null 2>&1; then
        echo "aws CLI not found; skipping EKS cleanup"
        exit 0
      fi

      if ! command -v kubectl >/dev/null 2>&1; then
        echo "kubectl not found; skipping EKS cleanup"
        exit 0
      fi

      aws eks update-kubeconfig \
        --region ${self.triggers.region} \
        --name ${self.triggers.cluster_name} >/dev/null 2>&1 || exit 0

      kubectl delete svc -A --field-selector spec.type=LoadBalancer --ignore-not-found=true --wait=true || true
      kubectl delete ingress -A --all --ignore-not-found=true || true
      kubectl delete nodeclaims,nodepools -A --all --ignore-not-found=true || true

      for i in $(seq 1 30); do
        remaining=$(kubectl get svc -A --field-selector spec.type=LoadBalancer --no-headers 2>/dev/null | wc -l | tr -d ' ')
        [ "$remaining" = "0" ] && break
        sleep 10
      done
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}
