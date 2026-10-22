variable "chosentype" {
  type = string
  default = "DEVELOPER"
  description = "Chosen Environment Variable (TEST, DEVELOPER, PRODUCTION)"
}

variable "chosenregion" {
  type = string
  default = "us-east-1"
  description = "Chosen Region Variable (Sandbox access on: us-east-1, us-west-2)"
}

variable "db_password" {
  type        = string
  description = "Password for the RDS MySQL instance"
  sensitive   = true
}

variable "ssh_name" {
  type        = string
  description = "Name of the EC2 SSH Key Pair"
  default     = "vockey"
}

variable "iam_instance_profile_name" {
  type        = string
  description = "IAM Instance Profile name for EC2 ECS instances"
  default     = "LabInstanceProfile"
}