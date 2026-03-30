terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }

  # Remote State Backend Configuration
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstatejerneystore123"       # This must be globally unique
    container_name       = "tfstate"
    key                  = "aks-jerney-demo.tfstate"   # The name of the state file inside the container
    use_oidc             = true                       # Tells Terraform to use the GitHub Actions OIDC token
  }
}

provider "azurerm" {
  features {}
  use_oidc = true # Ensures the provider also uses the OIDC token for deployments
}
