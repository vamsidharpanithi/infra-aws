variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "service_account" {
  description = "Service account to associate with the IAM role"
  type        = string
  default     = "211125357002"
}

variable "cluster_enabled_log_types" {
  description = "A list of the desired control plane logs to enable. For more information, see Amazon EKS Control Plane Logging documentation (https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html)"
  type        = list(string)
  default     = ["audit", "api", "authenticator", "controllerManager", "scheduler"]
}

variable "authentication_mode" {
  description = "The authentication mode for the cluster. Valid values are `CONFIG_MAP`, `API` or `API_AND_CONFIG_MAP`"
  type        = string
  default     = "API_AND_CONFIG_MAP"
}

variable "instance_types" {
  description = "A list of instance types to use for the worker nodes. For example, [\"t3.medium\", \"t3.large\"]"
  type        = list(string)
  default     = ["c3.large"]
}

variable "ami_type" {
  description = "The type of Amazon EKS optimized AMI to use for the worker nodes. Valid values are AL2_x86_64 and AL2_x86_64_GPU"
  type        = string
  default     = "AL2_x86_64"
}

variable "cluster_ip_family" {
  description = "The IP address family for the EKS cluster. Valid values are `ipv4` and `dualstack`"
  type        = string
  default     = "ipv4"
}
