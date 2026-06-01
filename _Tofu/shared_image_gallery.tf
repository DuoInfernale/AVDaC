##################################
##  AVD - Shared Image Gallery  ##
##################################
resource "azurerm_user_assigned_identity" "avd-user-assigned-identity" {
  name                = "${var.customer_abbreviation}-id-avd-shared-images-${var.environment}-${var.location}-01"
  resource_group_name = azurerm_resource_group.avd-shared-image-gallery.name
  location            = azurerm_resource_group.avd-shared-image-gallery.location
  tags                = var.tags
}

resource "azurerm_role_definition" "avd-user-assigned-identity-custom-rbac" {
  name        = "AVD - Azure Image Builder"
  scope       = data.azurerm_subscription.current.id
  description = "Azure Image Builder permissions"

  permissions {
    actions = [
      "Microsoft.Compute/images/write",
      "Microsoft.Compute/images/read",
      "Microsoft.Compute/images/delete",
      "Microsoft.Compute/galleries/read",
      "Microsoft.Compute/galleries/images/read",
      "Microsoft.Compute/galleries/images/versions/read",
      "Microsoft.Compute/galleries/images/versions/write"
    ]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.current.id,
    azurerm_resource_group.avd-shared-image-gallery.id,
    azurerm_resource_group.avd-shared-image-gallery-staging.id
  ]
}

resource "azurerm_storage_account" "avd-shared-image-gallery-storage" {
  name                     = "${var.customer_abbreviation}stscripts${var.environment}01"
  resource_group_name      = azurerm_resource_group.avd-shared-image-gallery.name
  location                 = azurerm_resource_group.avd-shared-image-gallery.location
  tags                     = var.tags
  account_tier             = "Standard"
  account_kind             = "StorageV2"
  account_replication_type = "LRS"
  access_tier              = "Hot"
  min_tls_version          = "TLS1_2"
}

resource "azurerm_storage_container" "avd-shared-image-gallery-storage-container-scripts" {
  name                  = "scripts"
  storage_account_id    = azurerm_storage_account.avd-shared-image-gallery-storage.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "avd-shared-image-gallery-storage-container-arm-wvd-templates" {
  name                  = "arm-wvd-templates"
  storage_account_id    = azurerm_storage_account.avd-shared-image-gallery-storage.id
  container_access_type = "private"
}

resource "azurerm_storage_blob" "avd-shared-image-gallery-storage-container-arm-wvd-templates-dsc-configuration" {
  name                   = "Configuration.zip"
  storage_account_name   = azurerm_storage_account.avd-shared-image-gallery-storage.name
  storage_container_name = azurerm_storage_container.avd-shared-image-gallery-storage-container-arm-wvd-templates.name
  type                   = "Block"
  source_uri             = "https://raw.githubusercontent.com/Azure/RDS-Templates/master/ARM-wvd-templates/DSC/Configuration.zip"
}

resource "azurerm_role_assignment" "avd-shared-image-gallery-storage-storage-blob-data-reader" {
  scope                = azurerm_storage_account.avd-shared-image-gallery-storage.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.avd-user-assigned-identity.principal_id
}

resource "azurerm_role_assignment" "avd-shared-image-gallery-custom-rbac-role-assignment" {
  scope                = azurerm_resource_group.avd-shared-image-gallery.id
  role_definition_name = azurerm_role_definition.avd-user-assigned-identity-custom-rbac.name
  principal_id         = azurerm_user_assigned_identity.avd-user-assigned-identity.principal_id
}

resource "azurerm_role_assignment" "avd-shared-image-gallery-rbac-role-assignment-staging" {
  scope                = azurerm_resource_group.avd-shared-image-gallery-staging.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.avd-user-assigned-identity.principal_id
}

resource "azurerm_shared_image_gallery" "avd-shared-image-galleries" {
  name                = "${var.customer_abbreviation}gal${var.environment}${var.location}01"
  resource_group_name = azurerm_resource_group.avd-shared-image-gallery.name
  location            = azurerm_resource_group.avd-shared-image-gallery.location
  tags                = var.tags
}

resource "azurerm_shared_image" "avd-shared-images" {
  for_each = { for img in var.avd-images : img.sku => img }

  name                                = each.value.sku
  accelerated_network_support_enabled = true
  architecture                        = "x64"
  description                         = ""
  disk_controller_type_nvme_enabled   = true
  disk_types_not_allowed              = []
  eula                                = ""
  gallery_name                        = azurerm_shared_image_gallery.avd-shared-image-galleries.name
  hibernation_enabled                 = true
  hyper_v_generation                  = "V2"
  location                            = azurerm_shared_image_gallery.avd-shared-image-galleries.location
  max_recommended_memory_in_gb        = 32
  max_recommended_vcpu_count          = 16
  min_recommended_memory_in_gb        = 8
  min_recommended_vcpu_count          = 1
  os_type                             = "Windows"
  privacy_statement_uri               = ""
  release_note_uri                    = ""
  resource_group_name                 = azurerm_shared_image_gallery.avd-shared-image-galleries.resource_group_name
  specialized                         = false
  tags                                = var.tags
  trusted_launch_enabled              = true
  identifier {
    offer     = each.value.offer
    publisher = each.value.publisher
    sku       = each.value.sku
  }
}
