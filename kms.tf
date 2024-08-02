data "aws_caller_identity" "current" {}

module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 1.5"

  aliases               = ["eks/pliao-key1"]
  description           = "pliao-test cluster encryption key"
  enable_default_policy = true
  key_owners            = [data.aws_caller_identity.current.arn]
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

