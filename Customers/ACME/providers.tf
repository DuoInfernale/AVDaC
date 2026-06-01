terraform {
  backend "azurerm" {
    resource_group_name  = "temp-state"
    storage_account_name = "avdtofustate"
    container_name       = "avd"
    key                  = "acme_avd.tfstate"
    use_azuread_auth     = true
  }
}
