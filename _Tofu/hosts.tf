#####################
##  Session Hosts  ##
#####################
locals {
  session_host_vms = merge([
    for host in var.avd-session_hosts : {
      for i in range(host.session_host_count) : "${host.name}-${i + 1}" => merge(host, {
        index               = i + 1,
        resource_group_name = azurerm_resource_group.avd-hostpools[host.host_pool_name].name
        location            = azurerm_resource_group.avd-hostpools[host.host_pool_name].location
      })
    }
  ]...)

  subnet_names = toset(var.avd-session_hosts.*.spoke_subnet_name)

  dsc_configuration_blob_sas_url = "${azurerm_storage_account.avd-shared-image-gallery-storage.primary_blob_endpoint}${azurerm_storage_container.avd-shared-image-gallery-storage-container-arm-wvd-templates.name}/${azurerm_storage_blob.avd-shared-image-gallery-storage-container-arm-wvd-templates-dsc-configuration.name}?${data.azurerm_storage_account_blob_container_sas.arm_wvd_templates.sas}"
}

data "azurerm_subnet" "spoke" {
  for_each = local.subnet_names

  name                 = each.value
  virtual_network_name = data.azurerm_virtual_network.spoke.name
  resource_group_name  = data.azurerm_virtual_network.spoke.resource_group_name
}

resource "azurerm_availability_set" "avd-session-host-availability-sets" {
  for_each = { for host_pool in var.avd-host_pools : host_pool.name => host_pool }

  name                         = "${var.customer_abbreviation}-avail-${var.environment}-${var.location}-${each.key}"
  resource_group_name          = azurerm_resource_group.avd-hostpools[each.key].name
  location                     = azurerm_resource_group.avd-hostpools[each.key].location
  platform_update_domain_count = each.value.platform_update_domain_count
  platform_fault_domain_count  = each.value.platform_fault_domain_count
  tags                         = var.tags
}

resource "azurerm_network_interface" "avd-session-host-nics" {
  for_each = local.session_host_vms

  name                = format("%savdwc-%02d-%02d-nic", var.customer_abbreviation, split("-", each.key)[0], each.value.index)
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  dns_servers         = lookup(each.value, "dns_servers", null)

  ip_configuration {
    name                          = "ipconfig1"
    primary                       = true
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = data.azurerm_subnet.spoke[each.value.spoke_subnet_name].id
  }

  accelerated_networking_enabled = true
  tags                           = var.tags
}

resource "random_password" "avd-session-hosts-password" {
  for_each = local.session_host_vms

  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_windows_virtual_machine" "avd-session-hosts" {
  for_each = local.session_host_vms

  name                  = format("%savdwc-%02d-%02d", var.customer_abbreviation, split("-", each.key)[0], each.value.index)
  computer_name         = format("%savdwc-%02d-%02d", var.customer_abbreviation, split("-", each.key)[0], each.value.index)
  resource_group_name   = each.value.resource_group_name
  location              = each.value.location
  size                  = each.value.size
  admin_username        = "avdlocaladmin"
  admin_password        = random_password.avd-session-hosts-password[each.key].result
  network_interface_ids = [azurerm_network_interface.avd-session-host-nics[each.key].id]
  availability_set_id   = azurerm_availability_set.avd-session-host-availability-sets[each.value.host_pool_name].id
  timezone              = lookup(each.value, "timezone", null)

  identity {
    type = "SystemAssigned"
  }

  dynamic "plan" {
    for_each = lookup(each.value, "plan", null) != null ? [1] : []
    content {
      name      = each.value.plan.name
      product   = each.value.plan.product
      publisher = each.value.plan.publisher
    }
  }

  ### Only one of either source_image_id or source_image_reference can be provided. If statement ensures only one of the exists.
  source_image_id = lookup(each.value, "source_image_reference", null) == null ? lookup(each.value, "source_image_id", null) : null
  dynamic "source_image_reference" {
    for_each = lookup(each.value, "source_image_id", null) == null ? (lookup(each.value, "source_image_reference", null) != null ? [1] : []) : []
    content {
      offer     = each.value.source_image_reference.offer
      publisher = each.value.source_image_reference.publisher
      sku       = each.value.source_image_reference.sku
      version   = each.value.source_image_reference.version
    }
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  secure_boot_enabled        = true
  vtpm_enabled               = true
  encryption_at_host_enabled = true


  tags = var.tags

  lifecycle {
    ignore_changes = [
      identity
    ]
  }
}

### Conditional deployment of Entra ID join
resource "azurerm_virtual_machine_extension" "avd-session-host-azuread-join" {
  for_each = { for k, v in local.session_host_vms : k => v if v.entra_domain_join_type == "azuread" ? true : false }

  name                       = "AADLoginForWindows"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd-session-hosts[each.key].id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "2.0"
  auto_upgrade_minor_version = true
  tags                       = azurerm_windows_virtual_machine.avd-session-hosts[each.key].tags

  settings = <<-SETTINGS
    {
      "mdmId": "0000000a-0000-0000-c000-000000000000"
    }
    SETTINGS
}

resource "azurerm_virtual_machine_extension" "avd-session-host-registration" {
  for_each = local.session_host_vms

  name                 = "AddSessionHost"
  virtual_machine_id   = azurerm_windows_virtual_machine.avd-session-hosts[each.key].id
  publisher            = "Microsoft.Powershell"
  type                 = "DSC"
  type_handler_version = "2.83"
  tags                 = azurerm_windows_virtual_machine.avd-session-hosts[each.key].tags

  settings = jsonencode({
    modulesUrl            = local.dsc_configuration_blob_sas_url
    configurationFunction = "Configuration.ps1\\AddSessionHost"
    properties = {
      hostPoolName = azurerm_virtual_desktop_host_pool.avd-host_pools[each.value.host_pool_name].name
      aadJoin      = true
    }
  })

  protected_settings = <<-PROTECTED_SETTINGS
    {
      "properties": {
        "registrationInfoToken": "${azurerm_virtual_desktop_host_pool_registration_info.avd-host_pool_registrations[each.value.host_pool_name].token}"
      }
    }
    PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [settings, protected_settings]
  }

  depends_on = [
    azurerm_virtual_desktop_host_pool.avd-host_pools,
    azurerm_virtual_machine_extension.avd-session-host-azuread-join
  ]
}

resource "azurerm_virtual_machine_extension" "avd-session-host-monitor-windows-agent" {
  for_each = { for k, v in local.session_host_vms : k => v if v.entra_domain_join_type == "azuread" ? true : false }

  name                       = "AzureMonitorWindowsAgent"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd-session-hosts[each.key].id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.34"
  auto_upgrade_minor_version = true
  tags                       = azurerm_windows_virtual_machine.avd-session-hosts[each.key].tags

  depends_on = [
    azurerm_virtual_desktop_host_pool.avd-host_pools,
    azurerm_virtual_machine_extension.avd-session-host-azuread-join,
    azurerm_virtual_machine_extension.avd-session-host-registration
  ]
}
