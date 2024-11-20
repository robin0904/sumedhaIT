variable "keypair_name" {
  type = string
}

# Instance name for tagging the Windows server
variable "instance_name" {
  description = "Name tag for the Windows server instance"
  type        = string
}

variable "name" {
  description = "Name tag for the instance"
  type = string
  default = "SumedhaLabs_Server"
}
