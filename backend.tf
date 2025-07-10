# backend.tf
terraform {
  backend "azurerm" {
    # The name of the Azure Resource Group where the state file will be stored.
    # This Resource Group must be created before running Terraform.
    resource_group_name  = "tfstate-rg-yourname" # <-- CHANGE this to your unique name

    # The globally unique Storage Account name where the state file will be stored.
    # This Storage Account must be created manually before running Terraform.
    storage_account_name = "yoobeetfstateyourname" # <-- CHANGE this to your unique name

    # The name of the container within the Storage Account where the state file will reside.
    # This container must also be created manually before running Terraform.
    container_name       = "tfstate"

    # The name of the blob (file) within the container where the state will be saved.
    key                  = "yoobee-migration/terraform.tfstate"
  }
}
