


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.36"

  cluster_name    = local.name
  cluster_version = "1.32"

  enable_cluster_creator_admin_permissions = true

  # Public API enabled, but locked down to YOUR IP only
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access_cidrs = [
    "8.29.230.89/32",
    "16.59.37.201/32"
  ]

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    core = {
      instance_types = ["t3.large", "t3a.large"]

      min_size     = 1
      desired_size = 1
      max_size     = 2

      disk_size = 50
    }

    gpu = {
      instance_types = ["g5.xlarge"]

      min_size     = 0
      desired_size = 0
      max_size     = 1

      disk_size = 100

      taints = [{
        key    = "nvidia.com/gpu"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]

      labels = {
        "node.kubernetes.io/accelerator" = "nvidia-a10g"
      }
    }
  }

  node_security_group_tags = {
    "karpenter.sh/discovery" = local.name
  }
}

output "configure_kubectl" {
  description = "Configure kubectl"
  value       = "aws eks --region ${local.region} update-kubeconfig --name ${module.eks.cluster_name}"
}

