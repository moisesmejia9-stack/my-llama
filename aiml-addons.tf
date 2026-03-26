

terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.4"
    }
  }
}

locals {
  jupyterhub_namespace            = "jupyterhub"
  jupyterhub_single_user_sa_name  = "${module.eks.cluster_name}-jupyterhub-single-user"
  catalog_sa_name                 = "catalog-sa"

  jupyterhub_values_template = data.http.jupyterhub_values.response_body

  jupyterhub_values_rendered = replace(
    replace(
      replace(
        local.jupyterhub_values_template,
        "$${jupyter_single_user_sa_name}",
        kubernetes_service_account_v1.jupyterhub_single_user_sa.metadata[0].name
      ),
      "$${region}",
      local.region
    ),
    "$${jupyter_pwd}",
    random_password.jupyter_pwd.result
  )
}

resource "kubernetes_namespace" "jupyterhub" {
  metadata {
    name = local.jupyterhub_namespace
  }

  depends_on = [module.eks]
}

resource "random_password" "jupyter_pwd" {
  length           = 16
  special          = true
  override_special = "_%@"
}

output "jupyter_pwd" {
  value     = random_password.jupyter_pwd.result
  sensitive = true
}

module "jupyterhub_single_user_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.58"

  role_name = "${module.eks.cluster_name}-jupyterhub-single-user-sa"

  role_policy_arns = {
    policy = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  }

  oidc_providers = {
    main = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "${local.jupyterhub_namespace}:${local.jupyterhub_single_user_sa_name}"
      ]
    }
  }

  depends_on = [
    module.eks,
    kubernetes_namespace.jupyterhub
  ]
}

resource "kubernetes_service_account_v1" "jupyterhub_single_user_sa" {
  metadata {
    name      = local.jupyterhub_single_user_sa_name
    namespace = kubernetes_namespace.jupyterhub.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = module.jupyterhub_single_user_irsa.iam_role_arn
    }
  }

  automount_service_account_token = true

  depends_on = [module.jupyterhub_single_user_irsa]
}

data "http" "jupyterhub_values" {
  url = "https://kubernetes-for-genai-models.s3.amazonaws.com/chapter5/jupyterhub-values.yaml"
}

module "eks_data_addons" {
  source  = "aws-ia/eks-data-addons/aws"
  version = "~> 1.37"

  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_nvidia_device_plugin = true
  nvidia_device_plugin_helm_config = {
    name    = "nvidia-device-plugin"
    version = "0.17.1"
  }

  enable_jupyterhub = true
  jupyterhub_helm_config = {
    version = "3.2.1"
    values  = [local.jupyterhub_values_rendered]
  }

  depends_on = [
    module.eks,
    kubernetes_namespace.jupyterhub,
    kubernetes_service_account_v1.jupyterhub_single_user_sa
  ]
}

module "catalog_rag_api_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.58"

  role_name = "${module.eks.cluster_name}-catalog-sa"

  role_policy_arns = {
    policy = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  }

  oidc_providers = {
    main = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "default:${local.catalog_sa_name}"
      ]
    }
  }

  depends_on = [module.eks]
}

resource "kubernetes_service_account_v1" "catalog_rag_api_sa" {
  metadata {
    name      = local.catalog_sa_name
    namespace = "default"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.catalog_rag_api_irsa.iam_role_arn
    }
  }

  automount_service_account_token = true

  depends_on = [module.catalog_rag_api_irsa]
}
