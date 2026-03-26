module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.21"

  cluster_name       = module.eks.cluster_name
  cluster_endpoint   = module.eks.cluster_endpoint
  cluster_version    = module.eks.cluster_version
  oidc_provider_arn  = module.eks.oidc_provider_arn

  enable_aws_load_balancer_controller = true

  depends_on = [module.eks]
}

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.0"

  cluster_name            = module.eks.cluster_name
  enable_irsa             = true
  irsa_oidc_provider_arn  = module.eks.oidc_provider_arn

  depends_on = [module.eks]
}
