#######################
##  Resource Groups  ##
#######################
resource "azurerm_resource_group" "avd-mgmt" {
  name     = "${var.customer_abbreviation}-rg-avd-mgmt-${var.environment}-${var.location}-01"
  location = var.location
  tags     = var.tags
}

resource "azurerm_resource_group" "avd-shared-image-gallery" {
  name     = "${var.customer_abbreviation}-rg-avd-shared-image-gallery-${var.environment}-${var.location}-01"
  location = var.location
  tags     = var.tags
}

resource "azurerm_resource_group" "avd-shared-image-gallery-staging" {
  name     = "${var.customer_abbreviation}-rg-avd-shared-image-gallery-staging-${var.environment}-${var.location}-01"
  location = var.location
  tags     = var.tags
}

resource "azurerm_resource_group" "avd-hostpools" {
  for_each = { for host_pool in var.avd-host_pools : host_pool.name => host_pool }

  name     = "${var.customer_abbreviation}-rg-avd-hostpool-${var.environment}-${var.location}-${each.key}"
  location = var.location
  tags     = var.tags
}
