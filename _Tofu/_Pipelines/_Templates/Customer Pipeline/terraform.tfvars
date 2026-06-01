# Customer OpenTofu variable template for AVD deployments.
# Copy this file to the customer folder, for example:
# Customers/<CustomerName>/terraform.tfvars
# Replace all sample values with customer-specific values before running plan/apply.

# Short customer code used in resource names.
customer_abbreviation = "<customer-abbreviation>"

# Environment name, for example: dev, test, prod.
environment = "<environment>"

# Primary Azure region for shared/customer resources.
location = "<primary-azure-region>"

# Azure region for Azure Virtual Desktop resources.
location_avd = "<avd-azure-region>"

# Existing spoke virtual network used by AVD session hosts.
spoke_vnet_name    = "<spoke-vnet-name>"
spoke_vnet_rg_name = "<spoke-vnet-resource-group-name>"

tags = {
  managedBy = "opentofu"
  workload  = "avd"
  project   = "<project-name>"
}

avd-host_pools = [
  {
    # Host pool suffix/name part used by the module.
    name = "<host-pool-name>"

    friendly_name                = "<host-pool-friendly-name>"
    description                  = "<host-pool-description>"
    type                         = "Pooled"
    load_balancer_type           = "BreadthFirst"
    start_vm_on_connect          = false
    custom_rdp_properties        = "drivestoredirect:s:*;audiomode:i:0;videoplaybackmode:i:1;redirectclipboard:i:1;redirectprinters:i:1;devicestoredirect:s:*;enablecredsspsupport:i:1;redirectwebauthn:i:1;use multimon:i:1;autoreconnection enabled:i:1;bandwidthautodetect:i:1;networkautodetect:i:1;compression:i:0;audiocapturemode:i:1;encode redirected video capture:i:1;camerastoredirect:s:*;redirectlocation:i:0;keyboardhook:i:0;maximizetocurrentdisplays:i:1;singlemoninwindowedmode:i:1;screen mode id:i:2;smart sizing:i:1;dynamic resolution:i:1;enablerdsaadauth:i:1"
    maximum_sessions_allowed     = 12
    platform_update_domain_count = 5
    platform_fault_domain_count  = 2
    preferred_app_group_type     = "Desktop"
  }
]

avd-application_groups = [
  {
    name                      = "<application-group-name>"
    friendly_name             = "<application-group-friendly-name>"
    description               = "<application-group-description>"
    type                      = "Desktop"
    host_pool_name            = "<host-pool-name>"
    avd_users_group_object_id = "<entra-id-avd-users-group-object-id>"
  }
]

# Optional RemoteApp definitions. Leave empty for desktop-only deployments.
avd-applications = []

avd-session_hosts = [
  {
    name                      = "<session-host-name>"
    session_host_count        = 1
    avd_users_group_object_id = "<entra-id-avd-users-group-object-id>"
    size                      = "<azure-vm-size>"
    timezone                  = "<windows-time-zone>"
    host_pool_name            = "<host-pool-name>"
    spoke_subnet_name         = "<spoke-subnet-name>"

    # Supported examples: azuread, entra, active-directory, hybrid.
    entra_domain_join_type    = "azuread"

    # Replace with the required marketplace or custom image settings.
    source_image_reference = {
      publisher = "MicrosoftWindowsDesktop"
      offer     = "windows-11"
      sku       = "win11-25h2-avd"
      version   = "latest"
    }
  }
]

avd-fslogix = [
  {
    name                     = "<fslogix-storage-name>"
    account_tier             = "Premium"
    account_kind             = "FileStorage"
    account_replication_type = "ZRS"
    access_tier              = "Hot"

    # For Entra ID joined session hosts, keep these values empty/null.
    # For AD DS/hybrid scenarios, provide the domain values required by the module.
    entra_domain_join_type   = null
    domain_name              = ""
    domain_guid              = ""
  }
]

avd-fslogix-file_shares = [
  {
    name  = "<fslogix-file-share-name>"
    quota = 100
  }
]

# Optional image definitions. Leave empty if marketplace images are used directly.
avd-images = []
