# Sample input values for this module/repository.
# Update values to match your Azure environment before running plan/apply.

customer_abbreviation = "acm"
environment           = "prod"
location              = "switzerlandnorth"
location_avd          = "westeurope"

spoke_vnet_name    = "prod-vnet-spoke-avd"
spoke_vnet_rg_name = "prod-rgr-network"

tags = {
  managedBy = "opentofu"
  workload  = "avd"
  project   = "avdac"
}

avd-host_pools = [
  {
    name                         = "01"
    friendly_name                = "Desktop Host Pool"
    description                  = "Primary pooled desktop host pool"
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
    name                      = "desktop-dag"
    friendly_name             = "Desktop Application Group"
    description               = "Default desktop app group"
    type                      = "Desktop"
    host_pool_name            = "01"
    avd_users_group_object_id = "2df2944a-1d54-48e4-a3d9-b01140647c5a"
  }
]

avd-applications = []

avd-session_hosts = [
  {
    name                      = "01"
    session_host_count        = 1
    avd_users_group_object_id = "2df2944a-1d54-48e4-a3d9-b01140647c5a"
    size                      = "Standard_D2as_v6"
    timezone                  = "W. Europe Standard Time"
    host_pool_name            = "01"
    spoke_subnet_name         = "prod-sne-avd-01"
    entra_domain_join_type    = "azuread"
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
    name                     = "fslogix"
    account_tier             = "Premium"
    account_kind             = "FileStorage"
    account_replication_type = "ZRS"
    access_tier              = "Hot"
    entra_domain_join_type   = null
    domain_name              = ""
    domain_guid              = ""
  }
]

avd-fslogix-file_shares = [
  {
    name  = "profiles"
    quota = 100
  }
]

avd-images = []
