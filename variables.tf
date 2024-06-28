variable "region" {
  description = "AWS region"
  type        = string
}

variable "service_account" {
  description = "Service account to associate with the IAM role"
  type        = string
}

variable "cluster_enabled_log_types" {
  description = "A list of the desired control plane logs to enable. For more information, see Amazon EKS Control Plane Logging documentation (https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html)"
  type        = list(string)
}

variable "authentication_mode" {
  description = "The authentication mode for the cluster. Valid values are `CONFIG_MAP`, `API` or `API_AND_CONFIG_MAP`"
  type        = string
}

variable "instance_types" {
  description = "A list of instance types to use for the worker nodes. For example, [\"t3.medium\", \"t3.large\"]"
  type        = list(string)
}

variable "ami_type" {
  description = "The type of Amazon EKS optimized AMI to use for the worker nodes. Valid values are AL2_x86_64 and AL2_x86_64_GPU"
  type        = string
}

variable "cluster_ip_family" {
  description = "The IP address family for the EKS cluster. Valid values are `ipv4` and `dualstack`"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "postgresPassword" {
  description = "Postgres Password"
  type        = string
}

variable "username" {
  description = "Postgres Username"
  type        = string
}

variable "password" {
  description = "Postgres Password"
  type        = string
}

variable "database" {
  description = "Postgres Database"
  type        = string
}
variable "postgresqlPort" {
  description = "Postgres Port"
  type        = string
}
