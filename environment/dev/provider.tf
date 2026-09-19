terraform {
    required_providers {
        azurerm = {
            source = "hashicorp/azurerm"
            version = "4.77.0"
        }
    }

 backend "azurerm" {
    resource_group_name = "remote-rg"
    storage_account_name = "remotestorageaccount22"
    container_name = "remotestate-container"
    key = "remote22.tfstate"
   
 }
}

provider "azurerm" {
    features {}
}