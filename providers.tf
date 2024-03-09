terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.91.0"
    }
  }
}

provider "azurerm" {
  alias                      = "cloud"
  skip_provider_registration = true
  subscription_id            = "subscription_id"
  features {}
}

provider "azurerm" {
  alias                      = "onprem"
  skip_provider_registration = true
  subscription_id            = "subscription_id"
  features {}
}