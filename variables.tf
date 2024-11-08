variable "keypair_name" {
  type = string
  default = "ssh_key"
}

# Instance name for tagging the Windows server
variable "instance_name" {
  description = "Name tag for the Windows server instance"
  type        = string
  default  = "SumedhaIT-server"
}

# Variable for your variables.tf file
variable "directory_id" {
  description = "The ID of the existing AWS Directory Service"
  type        = string
  default     = "d-9f6773508e"
}
