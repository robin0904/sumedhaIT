variable "keypair_name" {
  type = string
}

# Instance name for tagging the Windows server
variable "instance_name" {
  description = "Name tag for the EC2 Instance"
  type        = string
}

variable "name" {
  description = "Name tag for the Instance"
  type        = string
  default = "Sumedha-CloudLabs_Server-"

}

variable "instance_type" {
  description = "Instance Type variable"
  type        = string
}

variable "suffix" {
  description = "Suffix for the variables"
  type        = string
}