provider "aws" {
  region = var.region
}

locals {
  #The name must be unique within the AWS Region and AWS account that you're creating the cluster in.
  cluster_name = "peggyliao-test-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_addons = {
    aws-ebs-csi-driver = {
      service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
      # addon_version            = latest
      most_recent       = true
      resolve_conflicts = "PRESERVE"
    }

    eks-pod-identity-agent = {
      most_recent = true
    }
  }

  cluster_endpoint_public_access = true

  cluster_ip_family = "ipv4"

  cluster_name = local.cluster_name

  cluster_version = "1.29"

  create_kms_key = true
  cluster_encryption_config = [{
    resources = ["secrets"]
  }]

  kms_key_description           = "KMS Secrets encryption for EKS cluster."
  kms_key_enable_default_policy = true

  enable_cluster_creator_admin_permissions = true
  # enabled_cluster_log_types                = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    capacity_type  = "ON_DEMAND"
    instance_types = ["c3.large"]
  }
  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      min_size     = 3
      max_size     = 6
      desired_size = 3

      max_unavailable = 1
    }

    two = {
      name = "node-group-2"

      min_size     = 3
      max_size     = 6
      desired_size = 3

      max_unavailable = 1
    }
  }

  subnet_ids = module.vpc.private_subnets
  vpc_id     = module.vpc.vpc_id

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
