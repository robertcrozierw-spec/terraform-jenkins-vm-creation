//Single variable for resource group name, non default name is defined in relevant .tfvars file
variable "environment" {
 type        = string
 description = "Name of the environment to use for resources"
 default     = "DefaultEnvironment"
}