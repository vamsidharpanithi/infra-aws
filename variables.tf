# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "service_account" {
  description = "Service account to associate with the IAM role"
  type        = string
  default     = "211125357002"
}
