locals {
  #The name must be unique within the AWS Region and AWS account that you're creating the cluster in.
  cluster_name = "peggy-cluster"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "eks" {

  authentication_mode = var.authentication_mode

  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_addons = {
    aws-ebs-csi-driver = {
      service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
      most_recent              = true
      resolve_conflicts        = "PRESERVE"
    }

    eks-pod-identity-agent = {
      most_recent = true
    }

    coredns = {
      preserve    = true
      most_recent = true

      timeouts = {
        create = "25m"
        delete = "10m"
      }
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent          = true
      configuration_values = jsonencode({ "enableNetworkPolicy" : "true" })
    }
  }

  cluster_enabled_log_types = var.cluster_enabled_log_types

  cluster_endpoint_public_access = true

  cluster_ip_family = var.cluster_ip_family

  cluster_name = local.cluster_name

  cluster_version = "1.29"

  create_kms_key = false
  cluster_encryption_config = {
    provider_key_arn = module.kms.key_arn
    resources        = ["secrets"]
  }

  kms_key_description           = "KMS Secrets encryption for EKS cluster."
  kms_key_enable_default_policy = true

  enable_cluster_creator_admin_permissions = true

  eks_managed_node_group_defaults = {
    ami_type       = var.ami_type
    capacity_type  = "ON_DEMAND"
    instance_types = var.instance_types
  }
  eks_managed_node_groups = {
    one = {
      name            = "node-group-1"
      min_size        = 3
      max_size        = 6
      desired_size    = 3
      max_unavailable = 1

      block_device_mappings = [
        {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 20
            volume_type           = "gp2"
            encrypted             = true
            kms_key_id            = aws_kms_key.eks_node_kms.arn
            delete_on_termination = true
          }
        }
      ]
    }

    # two = {
    #   name            = "node-group-2"
    #   min_size        = 1
    #   max_size        = 1
    #   desired_size    = 1
    #   max_unavailable = 1

    #   block_device_mappings = [
    #     {
    #       device_name = "/dev/xvda"
    #       ebs = {
    #         volume_size           = 20
    #         volume_type           = "gp2"
    #         encrypted             = true
    #         kms_key_id            = aws_kms_key.eks_node_kms.arn
    #         delete_on_termination = true
    #       }
    #     }
    #   ]
    # }

    # three = {
    #   name            = "node-group-3"
    #   min_size        = 1
    #   max_size        = 1
    #   desired_size    = 1
    #   max_unavailable = 1

    #   block_device_mappings = [
    #     {
    #       device_name = "/dev/xvda"
    #       ebs = {
    #         volume_size           = 20
    #         volume_type           = "gp2"
    #         encrypted             = true
    #         kms_key_id            = aws_kms_key.eks_node_kms.arn
    #         delete_on_termination = true
    #       }
    #     }
    #   ]
    # }
  }


  subnet_ids = module.vpc.private_subnets
  vpc_id     = module.vpc.vpc_id

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

resource "kubernetes_namespace" "webapp_cve_processor" {
  metadata {
    name = "webapp-cve-processor"
  }

}

resource "kubernetes_namespace" "kafka" {
  metadata {
    name = "kafka"
    labels = {
    "istio-injection" = "enabled" }
  }
}

resource "kubernetes_namespace" "webapp_cve_consumer" {
  metadata {
    name = "webapp-cve-consumer"
    labels = {
    "istio-injection" = "enabled" }
  }
}
resource "kubernetes_namespace" "cluster_autoscaler" {
  metadata {
    name = "cluster-autoscaler"
  }
}

resource "kubernetes_namespace" "operator" {
  metadata {
    name = "cve-operator"
    labels = {
    "istio-injection" = "enabled" }
  }
}

resource "kubernetes_namespace" "cloud_watch" {
  metadata {
    name = "amazon-cloudwatch"
  }

}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }


}

resource "kubernetes_namespace" "istio" {
  metadata {
    name = "istio-system"
  }

}
resource "kubernetes_namespace" "external_dns" {
  metadata {
    name = "external-dns"
  }

}

