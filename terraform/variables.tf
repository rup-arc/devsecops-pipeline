variable "resource_group_name" {
  type        = string
  description = "The name of the resource group."
}

variable "location" {
  type        = string
  description = "The Azure region to deploy resources."
  default     = "eastus" # You can set defaults for values that rarely change
}

variable "acr_name" {
  type        = string
  description = "The globally unique name for the Azure Container Registry."
}

variable "cluster_name" {
  type        = string
  description = "The name of the AKS cluster."
}

variable "dns_prefix" {
  type        = string
  description = "The DNS prefix for the AKS cluster."
}

variable "node_count" {
  type        = number
  description = "The number of nodes in the default node pool."
  default     = 2
}
