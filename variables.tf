variable "keypair_name" {
  description = "EC2's Key Pair"
  type    = string
}

# Instance name for tagging the Windows server
variable "instance_name" {
  description = "EC2 Instance Server Name"
  type        = string
}

variable "name" {
  # Used for Prefix
  description = "Name tag for the Instance"
  type        = string
  default     = "Sumedha-CloudLabs_Server"
}

variable "instance_type" {
  description = "Instance Type for EC2"
  type        = string
}

variable "suffix" {
  description = "Suffix for the variables"
  type        = string
}