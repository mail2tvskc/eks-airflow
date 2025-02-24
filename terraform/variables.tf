#
# Variables Configuration
#

variable "env" {
  default = "sandbox"
  type    = string
}

variable "vpc_id" { default = "vpc-0c088867" }
variable "subnet_1" { default = "subnet-0425cbf9aa121e671" }
variable "subnet_2" { default = "subnet-07accfda00d1f3be0" }


variable "cluster_name" {
  default = "sandbox-eks-cluster"
  description = "Name of the EKS Cluster. This will be used to name auxilliary resources"
}

variable "cluster_desired_nodes" {
  default = 3
}

variable "cluster_max_nodes" {
  default = 4
}

variable "storage" {
  default     = "20"
  description = "Storage size in GB"
}

variable "engine" {
  default     = "postgres"
  description = "Engine type."
}

variable "engine_version" {
  description = "Engine version"
  default = "11.5"
}

variable "instance_class" {
  default     = "db.t2.small"
  description = "Instance class"
}

variable "db_name" {
  default     = "k8s-cluster_api_production"
  description = "db name"
}

variable "cidr_block_prefix" {
  default = "10.0"
  description = "ip range to use for vpc"
}
