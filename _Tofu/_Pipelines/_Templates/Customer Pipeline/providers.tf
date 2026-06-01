terraform {
  backend "azurerm" {
    # Azure Storage Account backend template for OpenTofu state.
    # Copy this file to the customer folder, for example:
    # Customers/<CustomerName>/providers.tf

    # Resource group containing the state storage account.
    resource_group_name = "<state-resource-group-name>"

    # Storage account used for remote state.
    storage_account_name = "<state-storage-account-name>"

    # Blob container used for state files.
    container_name = "<state-container-name>"

    # Unique state file name per customer/environment/workload.
    key = "<customer>-<environment>-avd.tfstate"

    # Use Microsoft Entra ID authentication instead of storage account keys.
    use_azuread_auth     = true
  }
}
