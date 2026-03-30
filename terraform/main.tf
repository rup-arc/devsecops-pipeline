terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }
}

provider "azurerm" {
  features {}
}

# 1. Resource Group
resource "azurerm_resource_group" "aks_rg" {
  name     = "rg-aks-jerney-demo"
  location = "eastus"
}

# 2. Azure Container Registry (ACR)
resource "azurerm_container_registry" "acr" {
  name                = "acraksjerneydemo123" # IMPORTANT: This must be globally unique. Change the numbers if it fails.
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
  sku                 = "Basic"            # Basic is perfect for personal projects
  admin_enabled       = false              # Security best practice: use managed identities instead of admin credentials
}

# 3. AKS Cluster (Official Module)
module "aks" {
  source  = "Azure/aks/azurerm"
  version = "8.0.0" 

  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
  prefix              = "aks-jerney"
  cluster_name        = "aks-jerney-demo-cluster"

  identity_type                     = "SystemAssigned"
  role_based_access_control_enabled = true

  network_plugin = "azure"
  network_policy = "azure"

  agents_count = 2
  agents_size  = "Standard_D2s_v3"

  log_analytics_workspace_enabled = false
}

# 4. Role Assignment: Allow AKS to pull images from ACR
resource "azurerm_role_assignment" "aks_to_acr" {
  principal_id                     = module.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true # Helps prevent timing issues during initial creation
}

# 5. Outputs for your GitHub Actions Pipeline
output "cluster_name" {
  value = module.aks.aks_name
}

output "resource_group_name" {
  value = azurerm_resource_group.aks_rg.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}
