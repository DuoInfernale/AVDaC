################################
##  Input Variables - Global  ##
################################
variable "customer_abbreviation" {
  description = "Customer abbreviation used in resource naming."
  type        = string
}

variable "environment" {
  description = "Environment the resources are deployed in. Expected values: prod, dev, test, qa, stage."
  type        = string
}

variable "location" {
  description = "Primary Azure location for non-AVD metadata resources."
  type        = string
}

variable "location_avd" {
  description = "Azure location for AVD metadata resources."
  type        = string
}

variable "tags" {
  description = "Tags to be applied to resources. Will be applied to all resources. Sending tags will overwrite the default tags."
  type        = map(string)
  default     = null
}


###############################
##  Log Analytics Workspace  ##
###############################
variable "law_retention_in_days" {
  description = "Number of days to retain logs in Log Analytics Workspace"
  type        = number
  default     = 365
}

variable "law_retention_in_days_table_perf" {
  description = "Number of days to retain table 'Perf' logs in Log Analytics Workspace"
  type        = number
  default     = 90
}

variable "log_export_settings" {
  description = "Send logs to a different log analytics workspace. Important: x-p-ix-devops-avd needs Monitoring Contributor access to the target Log Analytics Workspace"
  type = object({
    log_name                          = optional(string, "")
    target_log_analytics_workspace_id = optional(string, "") # The Log Analytics Workspace ID to link AVD diagnostics to
    enabled_logs_workspace            = optional(list(string), [])
    enabled_logs_host_pools           = optional(list(string), [])
    enabled_logs_application_groups   = optional(list(string), [])
  })
  default = {}

  validation {
    condition = (
      // allow both empty -> no log export
      (var.log_export_settings.log_name == "" && var.log_export_settings.target_log_analytics_workspace_id == "") ||
      // require both to be set -> export logs
      (var.log_export_settings.log_name != "" && var.log_export_settings.target_log_analytics_workspace_id != "")
    )
    error_message = "Please provide target_log_analytics_workspace_id and log_name when specifying log_export_settings"
  }

  validation {
    condition = sum([
      // when no properties are  provided, no enabled_logs need to be set (default)
      var.log_export_settings.log_name == "" ? 1 : 0,
      // check each individual parameter
      try(length(var.log_export_settings.enabled_logs_workspace), 0),
      try(length(var.log_export_settings.enabled_logs_host_pools), 0),
      try(length(var.log_export_settings.enabled_logs_application_groups), 0)
    ]) > 0
    error_message = "Please provide at least one enabled_log_* value"
  }
}

####################################
##  Input Variables - Host Pools  ##
####################################
variable "avd-host_pools" {
  description = "A list of objects with one object per host pool. See documentation below for values and examples."
  type = list(object({
    name                             = string                           # Name of Host Pool
    friendly_name                    = optional(string)                 # Pretty friendly name to be displayed
    description                      = optional(string)                 # Description of the Host Pool
    type                             = optional(string, "Pooled")       # Type of Host Pool. Possible values are "Pooled", "Personal". Defaults to "Pooled"
    load_balancer_type               = optional(string, "BreadthFirst") # Load Balancer Type. Possible values are "BreadthFirst", "DepthFirst", "Persistent". "Defaults to "BreadthFirst".
    validate_environment             = optional(bool, false)            # If environment should be validated or not. Defaults to "true"
    start_vm_on_connect              = optional(bool, false)            # Start VM when it's connected to. Defaults to "false"
    custom_rdp_properties            = optional(string)                 # A string of Custom RDP Properties to be applied to the Host Pool
    personal_desktop_assignment_type = optional(string, "Automatic")    # Personal Desktop Assignment Type. Possible values are "Automatic" and "Direct". Defaults to "Automatic"
    maximum_sessions_allowed         = optional(number, "12")           # Maximum number of users that have concurrent sessions on a session host. 0 - 999999. Should only be set if "type = Pooled"
    preferred_app_group_type         = optional(string)                 # Preferred Application Group type for the Host Pool. Valid options are "None", "Desktop", "RailApplications". Defaults to "None"
    platform_update_domain_count     = optional(number, 5)              # Availability Set Platform Update Domain count
    platform_fault_domain_count      = optional(number, 2)              # Availability Set Platform Fault Domain count
    tags                             = optional(map(string))            # Specify tags for the Host Pool. If not set, the main tags input is used. If no tags are set, default tags will be applied
    scheduled_agent_updates = optional(object({                         # Block defining Scheduled Agent Updates
      enabled                   = optional(bool, false)                 # If Scheduled Agents Updates should be enabled or not. Defaults to "false"
      timezone                  = optional(string)                      # Specify timezone for the schedule
      use_session_host_timezone = optional(bool, true)                  # Use the system timezone of the session host. Defaults to "true"
      schedule = optional(list(object({                                 # List of blocks defining schedules
        day_of_week = string                                            # Specify day of week. Possible values are "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturdai", "Sunday"
        hour_of_day = number                                            # The hour of day the update window should start. The update is a 2 hour period following the hour provided.
      })))                                                              # The value should be provided as a number between 0 and 23, with 0 being midnight and 23 being 11pm.
    }))                                                                 #
    registration_expiration_date = optional(string)                     # The date the registration token should expire. Recommended to use the time_offset resource for this
  }))
}

################################################
##  Input Variables - AVD Application Groups  ##
################################################
variable "avd-application_groups" {
  description = "A list of objects with one object per application group. See documentation below for values and examples."
  type = list(object({
    name                         = string                # Name of Application Group
    friendly_name                = optional(string)      # Pretty friendly name to be displayed
    description                  = optional(string)      # Description of the Application Group
    type                         = string                # Type of Application Group. Possible values are "RemoteApp" or "Desktop"
    host_pool_name               = string                # Name of Host Pool to be associated with the Application Group
    default_desktop_display_name = optional(string)      # Optionally set the Display Name for the default sessionDesktop desktop when "type = Desktop"
    tags                         = optional(map(string)) # Specify tags for the Host Pool. If not set, the main tags input is used. If no tags are set, default tags will be applied
    avd_users_group_object_id    = optional(string)      # Group ID of the Azure AD group that contains the users that should have access to the session hosts
  }))
  default = []
}

##########################################
##  Input Variables - AVD Applications  ##
##########################################
variable "avd-applications" {
  description = "A list of objects with one object per application. See documentation below for values and examples."
  type = list(object({
    name                         = string           # Name of Application
    friendly_name                = optional(string) # Pretty friendly name to be displayed
    description                  = optional(string) # Description of the application
    application_group_name       = string           # Name of Application Group for the Application to be associated with
    path                         = string           # The file path location of the app on the Virtual Desktop OS
    command_line_argument_policy = string           # Specifies whether this published application can be launched with command line arguments provided by the client, command line arguments specified at publish time, or no command line arguments at all. Possible values are #DoNotAllow", "Allow", "Require"
    command_line_arguments       = optional(string) # Command Line Arguments for Application
    show_in_portal               = optional(bool)   # Specifies whether to show the RemoteApp program in the RD Web Access Server. Possible values are "true" or "false"
    icon_path                    = optional(string) # Specifies the path for an icon which will be used for this Application
    icon_index                   = optional(string) # The index of the icon you wish to use
  }))
  default = []
}

#####################
##  AVD - FSLogix  ##
#####################
variable "avd-fslogix" {
  description = "An object describing the storage account and file share for FSLogix"
  type = list(object({
    name                               = optional(string, "fslogix")     # Name of Storage Account used for FSLogix
    account_tier                       = optional(string, "Premium")     # Account Tier of the Storage Account. Possible values are "Standard" or "Premium". Defaults to "Premium"
    account_kind                       = optional(string, "FileStorage") # Storage Account kind. Possible values are "BlobStorage", "BlockBlobStorage", "FileStorage", "Storage", "StorageV2". Defaults to "StorageV2"
    account_replication_type           = optional(string, "ZRS")         # Storage Account Replication Type. Possible values are "LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS". Defaults to "ZRS"
    access_tier                        = optional(string, "Hot")         # Storage Account Access Tier. Possible values are "Hot" or "Cool". Defaults to "Hot"
    entra_domain_join_type             = optional(string)                # Allowed values are "AD", "AADKERB", "AADDS". Defaults to "null" and no domain join is performed
    domain_name                        = string                          # The domain name to join the FSLogix Storage to
    domain_guid                        = string                          # The domain GUID to join the FSLogix Storage to
    terraform_deployment_spn_object_id = optional(string)                # Object ID of the Terraform Deployment Service Principal, to assign correct rights to the FSLogix storage account
  }))
  default = []
}

variable "avd-fslogix-file_shares" {
  description = "List of storage shares to create for AVD FSLogix"
  type = list(object({
    name  = string # Name of File Share for FSLogix
    quota = number # The maximum size of the share, in gigabytes
  }))
  default = []
}


###########################################
##  Input Variables - AVD Session Hosts  ##
###########################################
variable "avd-session_hosts" {
  description = "A list of objects with one object per session host. See documentation below for values and examples."
  type = list(object({
    name                      = string           # Name of session hosts
    session_host_count        = number           # Number of session hosts
    avd_users_group_object_id = optional(string) # Group ID of the Azure AD group that contains the users that should have access to the session hosts
    size                      = string           # VM Size SKU for the session hosts
    timezone                  = optional(string) # Specify timezone for the session hosts
    source_image_id           = optional(string) # One of either source_image_id or source_image_reference must be set
    source_image_reference = optional(object({   # Source Image Reference
      publisher = string                         # Image Publisher
      offer     = string                         # Image Offer
      sku       = string                         # Image SKU
      version   = string                         # Image Version
    }))                                          #
    plan = optional(object({                     # Plan for Microsoft Marketplace image
      name      = string                         # Image Name
      product   = string                         # Image Product
      publisher = string                         # Image Publisher
    }))                                          #                                                                     #
    dns_servers = optional(list(string))         # Specify DNS servers for the session hosts

    tags                           = optional(map(string))       # Map of tags to be set. If omitted, default tags will be applied                                                                   #
    entra_domain_join_type         = optional(string, "azuread") # Allowed values are "azuread" and "aadds"
    aadds_domain_name              = optional(string)            # Name of Azure Active Directory Domain Services to join the session hosts to
    aadds_avd_ou_path              = optional(string)            # Azure Active Directory Domain Services OU Path
    azuread_user_dc_admin_upn      = optional(string)            # DC Admin username
    azuread_user_dc_admin_password = optional(string)            # DC Admin password
    host_pool_name                 = string                      # Name of Host Pool for the Session Hosts to be joined to
    spoke_subnet_name              = string                      # Name of the subnet in the spoke VNET to be used for the session hosts
  }))
  default = []
}

###########################################
##  Input Variables - AVD Images  ##
###########################################
variable "avd-images" {
  description = "List of shared images to create in the gallery"
  type = list(object({
    offer     = string
    publisher = string
    sku       = string
  }))
  default = []
}
##################
##  Spoke VNET  ##
##################
variable "spoke_vnet_name" {
  description = "Name of the spoke VNET"
  type        = string
}

variable "spoke_vnet_rg_name" {
  description = "Name of the spoke VNET resource group"
  type        = string
}
