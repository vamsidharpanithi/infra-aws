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
resource "aws_kms_key" "eks_node_kms" {
  # alias_name = "webapp-kms-ec2"
  description              = "Ebs Encryption key"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  deletion_window_in_days  = 7
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Default",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${var.aws_account_id}:root"
        },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      {
        "Sid" : "KeyAdministration",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${var.service_account}:user/vamsidhardev",
            "arn:aws:iam::${var.service_account}:user/Peizhendev",
            "arn:aws:iam::${var.service_account}:user/mihirdev"
          ]
        },
        "Action" : [
          "kms:Update*",
          "kms:UntagResource",
          "kms:TagResource",
          "kms:ScheduleKeyDeletion",
          "kms:Revoke*",
          "kms:ReplicateKey",
          "kms:Put*",
          "kms:List*",
          "kms:ImportKeyMaterial",
          "kms:Get*",
          "kms:Enable*",
          "kms:Disable*",
          "kms:Describe*",
          "kms:Delete*",
          "kms:Create*",
          "kms:CancelKeyDeletion"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "Allow use of the key",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${var.service_account}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
          ]
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "Allow attachment of persistent resources",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${var.service_account}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
          ]
        },
        "Action" : [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ],
        "Resource" : "*",
        "Condition" : {
          "Bool" : {
            "kms:GrantIsForAWSResource" : "true"
          }
        }
      }
    ]
    }
  )
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
      most_recent = true
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
      min_size        = 1
      max_size        = 1
      desired_size    = 1
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
  }


  subnet_ids = module.vpc.private_subnets
  vpc_id     = module.vpc.vpc_id

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
