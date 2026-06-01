data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

data "azurerm_virtual_network" "spoke" {
  name                = var.spoke_vnet_name
  resource_group_name = var.spoke_vnet_rg_name
}

resource "time_rotating" "sas_rotation" {
  rotation_days = 30
}

data "azurerm_storage_account_blob_container_sas" "arm_wvd_templates" {
  depends_on        = [time_rotating.sas_rotation]
  connection_string = azurerm_storage_account.avd-shared-image-gallery-storage.primary_connection_string
  container_name    = azurerm_storage_container.avd-shared-image-gallery-storage-container-arm-wvd-templates.name
  https_only        = true

  start  = time_rotating.sas_rotation.rfc3339
  expiry = time_rotating.sas_rotation.rotation_rfc3339
  permissions {
    read   = true
    add    = false
    create = false
    write  = false
    delete = false
    list   = false
  }
}
