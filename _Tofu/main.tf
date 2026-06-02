######################################
##  AVD -  Log Analytics Workspace  ##
######################################
resource "azurerm_log_analytics_workspace" "avd-log-analytics-workspace" {
  name                = "${var.customer_abbreviation}-log-${var.environment}-${var.location}-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.avd-mgmt.name
  sku                 = "PerGB2018"
  retention_in_days   = var.law_retention_in_days
  tags                = var.tags
}

resource "azurerm_log_analytics_workspace_table" "avd-log-analytics-workspace-table-perf" {
  workspace_id            = azurerm_log_analytics_workspace.avd-log-analytics-workspace.id
  name                    = "Perf"
  retention_in_days       = var.law_retention_in_days_table_perf
  total_retention_in_days = var.law_retention_in_days_table_perf

  depends_on = [
    azurerm_monitor_data_collection_rule.avd-dcr
  ]
}

######################
##  AVD - KeyVault  ##
######################
resource "azurerm_key_vault" "avd-keyvault" {
  access_policy                   = []
  rbac_authorization_enabled      = true
  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = false
  location                        = azurerm_resource_group.avd-mgmt.location
  name                            = "${var.customer_abbreviation}-kv-${var.environment}-${var.location == "switzerlandnorth" ? "chn" : var.location}-01"
  public_network_access_enabled   = true
  purge_protection_enabled        = false
  resource_group_name             = azurerm_resource_group.avd-mgmt.name
  sku_name                        = "standard"
  soft_delete_retention_days      = 30
  tags                            = var.tags
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  network_acls {
    bypass                     = "None"
    default_action             = "Allow"
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }
}

resource "azurerm_role_assignment" "avd-key-vault-secrets-officer" {
  scope                = azurerm_key_vault.avd-keyvault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "avd-session-hosts-password" {
  for_each = random_password.avd-session-hosts-password

  name         = azurerm_windows_virtual_machine.avd-session-hosts[each.key].computer_name
  value        = each.value.result
  key_vault_id = azurerm_key_vault.avd-keyvault.id

  depends_on = [
    azurerm_role_assignment.avd-key-vault-secrets-officer
  ]
}

#####################
##  AVD Workspace  ##
#####################
resource "azurerm_virtual_desktop_workspace" "avd-workspace" {
  name                = "${var.customer_abbreviation}-vdws-${var.environment}-${var.location_avd}-01"
  resource_group_name = azurerm_resource_group.avd-mgmt.name
  location            = var.location_avd
  friendly_name       = "${upper(var.customer_abbreviation)} AVD"
  tags                = var.tags
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "avd-workspace-app_group-association" {
  for_each = { for ag in var.avd-application_groups : ag.name => ag } # Creates one association per app group.

  application_group_id = azurerm_virtual_desktop_application_group.avd-application_groups[each.key].id
  workspace_id         = azurerm_virtual_desktop_workspace.avd-workspace.id
}

resource "azurerm_monitor_diagnostic_setting" "avd-workspace-diagnostic" {
  name                       = "WVDInsights"
  target_resource_id         = azurerm_virtual_desktop_workspace.avd-workspace.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.avd-log-analytics-workspace.id

  enabled_log {
    category_group = "allLogs"
  }
  depends_on = [
    azurerm_virtual_desktop_workspace.avd-workspace
  ]
}

# log export settings for avd workspace to external law (e.g. sentinel)
resource "azurerm_monitor_diagnostic_setting" "workspace_additional_logs" {

  count = length(var.log_export_settings.enabled_logs_workspace) > 0 ? 1 : 0

  name                       = var.log_export_settings.log_name
  target_resource_id         = azurerm_virtual_desktop_workspace.avd-workspace.id
  log_analytics_workspace_id = var.log_export_settings.target_log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = var.log_export_settings.enabled_logs_workspace
    content {
      category = enabled_log.value
    }
  }
}

######################
##  AVD Host Pools  ##
######################
resource "azurerm_virtual_desktop_host_pool" "avd-host_pools" {
  for_each = { for host_pool in var.avd-host_pools : host_pool.name => host_pool }

  name                             = "${var.customer_abbreviation}-vdpool-${var.environment}-${var.location_avd}-${each.key}"
  resource_group_name              = azurerm_resource_group.avd-hostpools[each.key].name
  location                         = var.location_avd
  friendly_name                    = lookup(each.value, "friendly_name", null)
  description                      = lookup(each.value, "description", null)
  type                             = each.value.type
  load_balancer_type               = lookup(each.value, "load_balancer_type", null)
  validate_environment             = lookup(each.value, "validate_environment", null)
  start_vm_on_connect              = lookup(each.value, "start_vm_on_connect", null)
  custom_rdp_properties            = lookup(each.value, "custom_rdp_properties", null)
  personal_desktop_assignment_type = each.value.type == "Personal" ? lookup(each.value, "personal_desktop_assignment_type", null) : null
  maximum_sessions_allowed         = lookup(each.value, "maximum_sessions_allowed", null)
  preferred_app_group_type         = lookup(each.value, "preferred_app_group_type", null)
  tags                             = var.tags

  dynamic "scheduled_agent_updates" {
    for_each = try(each.value.scheduled_agent_updates, null) != null ? [1] : []

    content {
      enabled                   = lookup(each.value.scheduled_agent_updates, "enabled", null)
      timezone                  = lookup(each.value.scheduled_agent_updates, "timezone", null)
      use_session_host_timezone = lookup(each.value.scheduled_agent_updates, "use_session_host_timezone", null)

      dynamic "schedule" {
        #for_each = lookup(each.value.scheduled_agent_updates, "schedule", []) != [] ? { for s in each.value.scheduled_agent_updates.schedule : s.day_of_week => s } : []
        for_each = { for s in lookup(each.value.scheduled_agent_updates, "schedule", []) : s.day_of_week => s }

        content {
          day_of_week = lookup(s.value, "day_of_week", null)
          hour_of_day = lookup(s.value, "hour_of_day", null)
        }
      }
    }
  }
}

# log export settings for host pools to external law (e.g. sentinel)
resource "azurerm_monitor_diagnostic_setting" "host_pool_additional_logs" {

  // apply diagnostic setting to each hostpool
  // but only if there are logs enabled for the host pool
  for_each = { for host_pool in var.avd-host_pools : host_pool.name => host_pool if(length(var.log_export_settings.enabled_logs_host_pools) > 0) }

  name                       = var.log_export_settings.log_name
  target_resource_id         = azurerm_virtual_desktop_host_pool.avd-host_pools[each.key].id
  log_analytics_workspace_id = var.log_export_settings.target_log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = var.log_export_settings.enabled_logs_host_pools
    content {
      category = enabled_log.value
    }

  }
}

resource "time_rotating" "deployment-date" {
  for_each      = { for session_hosts in var.avd-session_hosts : session_hosts.name => session_hosts }
  rotation_days = 30
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "avd-host_pool_registrations" {
  for_each = { for host_pool in var.avd-host_pools : host_pool.name => host_pool }

  expiration_date = time_rotating.deployment-date[each.key].rotation_rfc3339
  hostpool_id     = azurerm_virtual_desktop_host_pool.avd-host_pools[each.key].id
}

resource "azurerm_monitor_diagnostic_setting" "avd-host_pools-diagnostic" {
  for_each = { for host_pool in var.avd-host_pools : host_pool.name => host_pool }

  name                       = "WVDInsights"
  target_resource_id         = azurerm_virtual_desktop_host_pool.avd-host_pools[each.key].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.avd-log-analytics-workspace.id

  enabled_log {
    category_group = "allLogs"
  }
  depends_on = [
    azurerm_virtual_desktop_host_pool.avd-host_pools
  ]
}

##############################
##  AVD Application Groups  ##
##############################
resource "azurerm_virtual_desktop_application_group" "avd-application_groups" {
  for_each = { for ag in var.avd-application_groups : ag.name => ag }

  name                         = "${var.customer_abbreviation}-vdag-${var.environment}-${var.location_avd}-${each.key}"
  friendly_name                = lookup(each.value, "friendly_name", null)
  description                  = lookup(each.value, "description", null)
  default_desktop_display_name = lookup(each.value, "default_desktop_display_name", null)
  resource_group_name          = azurerm_resource_group.avd-hostpools[each.value.host_pool_name].name
  location                     = var.location_avd
  type                         = each.value.type
  host_pool_id                 = azurerm_virtual_desktop_host_pool.avd-host_pools[each.value.host_pool_name].id
  tags                         = var.tags
}

resource "azurerm_role_assignment" "avd-application-groups-users" {
  for_each             = { for ag in var.avd-application_groups : ag.name => ag }
  scope                = azurerm_virtual_desktop_application_group.avd-application_groups[each.key].id
  principal_id         = each.value.avd_users_group_object_id
  role_definition_name = "Desktop Virtualization User"
}

resource "azurerm_role_assignment" "avd-virtual-machine-user-login" {
  for_each             = { for ag in var.avd-application_groups : ag.name => ag }
  scope                = azurerm_resource_group.avd-hostpools[each.value.host_pool_name].id
  principal_id         = each.value.avd_users_group_object_id
  role_definition_name = "Virtual Machine User Login"
}

# log export settings for application groups to external law (e.g. sentinel)
resource "azurerm_monitor_diagnostic_setting" "application_group_additional_logs" {

  // apply diagnostic setting to each application group
  // but only if there are logs enabled for the application group
  for_each = { for ag in var.avd-application_groups : ag.name => ag if(length(var.log_export_settings.enabled_logs_application_groups) > 0) }

  name                       = var.log_export_settings.log_name
  target_resource_id         = azurerm_virtual_desktop_application_group.avd-application_groups[each.key].id
  log_analytics_workspace_id = var.log_export_settings.target_log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = var.log_export_settings.enabled_logs_application_groups
    content {
      category = enabled_log.value
    }

  }
}

########################
##  AVD Applications  ##
########################
resource "azurerm_virtual_desktop_application" "avd-applications" {
  for_each = { for app in var.avd-applications : app.name => app }

  name                         = each.value.name
  friendly_name                = lookup(each.value, "friendly_name", null)
  description                  = lookup(each.value, "description", null)
  application_group_id         = azurerm_virtual_desktop_application_group.avd-application_groups[each.value.application_group_name].id
  path                         = each.value.path
  command_line_argument_policy = each.value.command_line_argument_policy
  command_line_arguments       = lookup(each.value, "command_line_arguments", null)
  show_in_portal               = lookup(each.value, "show_in_portal", null)
  icon_path                    = lookup(each.value, "icon_path", null)
  icon_index                   = lookup(each.value, "icon_index", null)
}

#####################
##  AVD - FSLogix  ##
#####################
resource "azurerm_storage_account" "avd-fslogix" {
  for_each = { for sa in var.avd-fslogix : sa.name => sa }

  name                     = "${var.customer_abbreviation}stfsl${var.environment}01"
  resource_group_name      = azurerm_resource_group.avd-mgmt.name
  location                 = azurerm_resource_group.avd-mgmt.location
  tags                     = var.tags
  account_tier             = each.value.account_tier
  account_kind             = each.value.account_kind
  account_replication_type = each.value.account_replication_type
  access_tier              = each.value.access_tier
  min_tls_version          = "TLS1_2"

  dynamic "azure_files_authentication" {
    for_each = each.value.entra_domain_join_type != null ? [1] : []

    content {
      default_share_level_permission = "StorageFileDataSmbShareContributor"
      directory_type                 = each.value.entra_domain_join_type
      active_directory {
        domain_name         = lookup(each.value, "domain_name", null)
        domain_guid         = lookup(each.value, "domain_guid", null)
        domain_sid          = " "
        forest_name         = " "
        netbios_domain_name = " "
        storage_sid         = " "
      }
    }
  }

  dynamic "share_properties" {
    for_each = each.value.entra_domain_join_type != null ? [1] : []

    content {
      retention_policy {
        days = 14
      }

      dynamic "smb" {
        for_each = share_properties.value == 1 ? [1] : []
        content {
          authentication_types            = ["Kerberos"]
          channel_encryption_type         = ["AES-128-GCM", "AES-256-GCM"]
          kerberos_ticket_encryption_type = ["AES-256"]
          multichannel_enabled            = true
          versions                        = ["SMB3.1.1"]
        }
      }
    }
  }
}

resource "azurerm_role_assignment" "avd-fslogix-smb-share-contributor-tf-deployment-spn" {
  for_each = { for sa in var.avd-fslogix : sa.name => sa if sa.entra_domain_join_type != null ? true : false }

  principal_id         = data.azurerm_client_config.current.object_id
  scope                = azurerm_storage_account.avd-fslogix[each.key].id
  role_definition_name = "Storage File Data SMB Share Contributor"
}

resource "azurerm_storage_share" "avd-fslogix-file-share" {
  for_each = { for share in var.avd-fslogix-file_shares : share.name => share }

  name               = each.value.name
  storage_account_id = azurerm_storage_account.avd-fslogix["fslogix"].id
  quota              = each.value.quota

  depends_on = [
    azurerm_role_assignment.avd-fslogix-smb-share-contributor-tf-deployment-spn
  ]
}

################################################
##  AVD - Data Collection Rule / Association  ##
################################################
resource "time_sleep" "wait_90_seconds" {
  depends_on = [azurerm_log_analytics_workspace.avd-log-analytics-workspace]

  create_duration = "90s"
}

resource "azurerm_monitor_data_collection_rule" "avd-dcr" {
  name                = "microsoft-avdi-switzerlandnorth"
  resource_group_name = azurerm_resource_group.avd-mgmt.name
  location            = azurerm_resource_group.avd-mgmt.location

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.avd-log-analytics-workspace.id
      name                  = azurerm_log_analytics_workspace.avd-log-analytics-workspace.name
    }
  }

  data_flow {
    streams      = ["Microsoft-Perf", "Microsoft-Event"]
    destinations = [azurerm_log_analytics_workspace.avd-log-analytics-workspace.name]
  }

  data_sources {
    performance_counter {
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 30
      counter_specifiers = [
        "\\LogicalDisk(C:)\\Avg. Disk Queue Length",
        "\\LogicalDisk(C:)\\Current Disk Queue Length",
        "\\Memory\\Available Mbytes",
        "\\Memory\\Page Faults/sec",
        "\\Memory\\Pages/sec",
        "\\Memory\\% Committed Bytes In Use",
        "\\PhysicalDisk(*)\\Avg. Disk Queue Length",
        "\\PhysicalDisk(*)\\Avg. Disk sec/Read",
        "\\PhysicalDisk(*)\\Avg. Disk sec/Transfer",
        "\\PhysicalDisk(*)\\Avg. Disk sec/Write",
        "\\Processor Information(_Total)\\% Processor Time",
        "\\System\\System Up Time",
        "\\User Input Delay per Process(*)\\Max Input Delay",
        "\\User Input Delay per Session(*)\\Max Input Delay"
      ]
      name = "perfCounterDataSource30"
    }

    performance_counter {
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60
      counter_specifiers = [
        "\\LogicalDisk(C:)\\% Free Space",
        "\\LogicalDisk(C:)\\Avg. Disk sec/Transfer"
      ]
      name = "perfCounterDataSource60"
    }

    windows_event_log {
      streams = ["Microsoft-Event"]
      x_path_queries = [
        "Microsoft-Windows-TerminalServices-RemoteConnectionManager/Admin!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]",
        "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]",
        "System!*",
        "Microsoft-FSLogix-Apps/Operational!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]",
        "Application!*[System[(Level=2 or Level=3)]]",
        "Microsoft-FSLogix-Apps/Admin!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]"
      ]
      name = "eventLogsDataSource"
    }
  }

  tags = var.tags
  depends_on = [
    time_sleep.wait_90_seconds,
    azurerm_log_analytics_workspace.avd-log-analytics-workspace
  ]
}

resource "azurerm_monitor_data_collection_rule_association" "avd-dcr-association" {
  for_each = local.session_host_vms

  name                    = azurerm_windows_virtual_machine.avd-session-hosts[each.key].name
  target_resource_id      = azurerm_windows_virtual_machine.avd-session-hosts[each.key].id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.avd-dcr.id

  depends_on = [
    azurerm_virtual_machine_extension.avd-session-host-monitor-windows-agent
  ]
}
