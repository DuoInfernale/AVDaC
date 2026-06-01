///// ---------------------- HEADER ---------------------- /////

// Main Bicep template for the deployment of an Azure Virtual Desktop (AVD) environment.
// This template deploys the following resources:
// - Resource groups
// - Virtual networks (spoke only)
// - Subnets (spoke only)
// - Private DNS zones
// - Private DNS links
// - Storage accounts
// - File shares
// - Private endpoints
// - Network security groups
// - AVD host pools
// - AVD application groups
// - AVD workspaces
// - AVD session hosts
//
// Authors: Michele Blum & Flavio Meyer
// Created: 01.03.2025
// Updated: 27.05.2026

///// ---------------------- HEADER END ---------------------- /////

///// ---------------------- CHANGELOG ---------------------- /////

// Version: 1.0.0
// Date: 01.03.2025
// Changes:
// - Initial version
//
// Version: 2.0.0
// Date: 27.05.2026
// Changes:
// - Removed hub network modules and hub subnet calculations
// - Removed automatic CIDR/subnet calculations
// - Added explicit parameter for the spoke subnet prefix

///// ---------------------- CHANGELOG END ---------------------- /////

///// ---------------------- SCOPE ---------------------- /////

// Deployment scoped to a subscription
targetScope = 'subscription'

///// ---------------------- SCOPE END ---------------------- /////

///// ---------------------- PARAMETERS ---------------------- /////
//// ---------------------- GLOBAL PARAMETERS ---------------------- ////

// Short customer abbreviation used in naming (must be set).
@minLength(1)
@maxLength(3)
param gpar_customerAbbreviation string

// Deployment environment tag (e.g., dev/test/prod) used in naming and tags.
@minLength(1)
@maxLength(4)
param gpar_environment string

// Tags object to apply to deployed resources (optional, defaults applied when empty).
@description('Tags to be applied to all deployed resources.')
param gpar_tags object = {}

//// ---------------------- GLOBAL PARAMETERS END ---------------------- ////
//// ---------------------- STATIC PARAMETERS ---------------------- ////

// Name for the spoke subnet that will host AVD session hosts.
@description('Name of the AVD spoke subnet')
param spar_snetNameSpokeAVD string = 'AVDSubnet'

//// ---------------------- STATIC PARAMETERS END ---------------------- ////
//// ---------------------- DYNAMIC PARAMETERS ---------------------- ////

// Subscription-level primary deployment location (required).
@description('Primary location for resources (subscription-level input).')
param dpar_location string

// AVD region for host pool and session hosts (if empty defaults applied via variables).
@description('AVD-specific location (region for hostpool and session hosts).')
param dpar_locationAVD string

// Address space to use for the spoke virtual network (explicit in v2.0.0).
@description('VNet address space for the spoke VNet (example: 10.100.0.0/20).')
param dpar_spokeVnetPrefix string

// Explicit subnet prefix for the AVD spoke subnet (no automatic calculation).
@description('Spoke subnet prefix for AVD (example: 10.100.1.0/24). Provide explicitly in v2.0.0.')
param dpar_spokeSubnetPrefix string[]

// Optional AVD workspace name; default generated when empty.
@description('AVD workspace name (optional). If empty a default name will be generated.')
param dpar_vdwsName string

// Optional AVD application group type (Desktop or RemoteApp); defaults to Desktop.
@description('AVD application group type (Desktop or RemoteApp). Defaults to Desktop.')
param dpar_vdagApplicationGroupType string

// Optional file share name for FSLogix profiles; default is 'fsl-profiles'.
@description('File share name for FSLogix profiles (optional, default: fsl-profiles).')
param dpar_stShareName string

// File share quota (GiB) for FSLogix / profile storage.
@description('File share quota (GiB).')
param dpar_fsshareQuota int

// Number of session host VMs to create.
@minValue(1)
@description('Number of session host VMs to create.')
param dpar_vmCount int

// VM size for session hosts.
@description('Size of the session host VMs.')
param dpar_vmSize string

// Private DNS zone name to create for privatelink resolution (e.g. privatelink.file.core.windows.net).
@description('Private DNS zone name to create for storage/private link (e.g. privatelink.file.core.windows.net)')
param dpar_privateDNSName string

// Local admin username for session hosts.
@description('Local admin username for the session hosts.')
param dpar_vmlocaladminName string

// Local admin password for session hosts (secure).
@secure()
@description('Local admin password for the session hosts.')
param dpar_vmlocaladminPassword string

// Object ID (Azure AD) of users who should be assigned to the Desktop Application Group.
@description('Object ID of the full desktop users (for app group RBAC).')
param dpar_rbacObjectIdFullDesktopUsers string

// Object ID (Azure AD) of users that require RBAC access to storage (FSLogix).
@description('Object ID of the AVD users (for storage access).')
param dpar_rbacObjectIdRBACAVDUsers string

// Object ID (Azure AD) of the AVD administrator (storage admin/elevated).
@description('Object ID of the AVD admin (for storage admin / elevated tasks).')
param dpar_rbacObjectIdRBACAVDAdmin string

//// ---------------------- DYNAMIC PARAMETERS END ---------------------- ////
///// ---------------------- PARAMETERS END ---------------------- /////

///// ---------------------- VARIABLES ---------------------- /////
///// ---------------------- BASIC VARIABLES ---------------------- ////

// Effective tags used throughout the deployment (uses provided tags or defaults).
var var_tags = empty(gpar_tags) ? {
  Environment: gpar_environment != '' ? gpar_environment : 'prod'
  Customer: gpar_customerAbbreviation != '' ? gpar_customerAbbreviation : 'duo'
} : gpar_tags

// Effective AVD region to use for host pools and session hosts (fallback default).
var var_locationAVD = dpar_locationAVD != '' ? dpar_locationAVD : 'westeurope'

// Resource group names used by modules (AVD, storage, network).
var var_rgAVDName = '${gpar_customerAbbreviation}-rg-avd-${gpar_environment != '' ? gpar_environment : 'prod'}-${dpar_location != '' ? dpar_location : 'switzerlandnorth'}-001'
var var_rgStorageName = '${gpar_customerAbbreviation}-rg-storage-${gpar_environment != '' ? gpar_environment : 'prod'}-${dpar_location != '' ? dpar_location : 'switzerlandnorth'}-001'
var var_rgNetworkName = '${gpar_customerAbbreviation}-rg-network-${gpar_environment != '' ? gpar_environment : 'prod'}-${dpar_location != '' ? dpar_location : 'switzerlandnorth'}-001'

///// ---------------------- BASIC VARIABLES END ---------------------- ////
///// ---------------------- NETWORKING VARIABLES (SPOKE ONLY) ---------------------- ////

// Spoke virtual network name.
var var_vnetNameSpokeAVD = '${gpar_customerAbbreviation}-vnet-spoke-avd-${gpar_environment != '' ? gpar_environment : 'prod'}-${var_locationAVD}-001'

// Private DNS link name used when linking private DNS zone to the spoke VNet.
var var_privateDNSLinkName = '${gpar_customerAbbreviation}-pl-${var_vnetNameSpokeAVD}'

// Default NSG name for the spoke resources (can be used by the subnet module).
var var_nsgDefaultName = '${gpar_customerAbbreviation}-nsg-default-${gpar_environment != '' ? gpar_environment : 'prod'}-${var_locationAVD}-001'

///// ---------------------- NETWORKING VARIABLES END ---------------------- ////
///// ---------------------- STORAGE VARIABLES ---------------------- ////

// Storage account name (FSLogix / profiles).
var var_stName = '${gpar_customerAbbreviation}stfsl${gpar_environment != '' ? gpar_environment : 'prod'}001'

// File share name for FSLogix profiles.
var var_stShareName = dpar_stShareName != '' ? dpar_stShareName :'fsl-profiles'

// Effective file share quota (GiB).
var var_stShareQuota = dpar_fsshareQuota != 0 ? dpar_fsshareQuota : 1024

// Private endpoint and DNS group names used for storage privatelink.
var var_pepName = '${gpar_customerAbbreviation}-pep-stfsl${gpar_environment != '' ? gpar_environment : 'prod'}001'
var var_privateDNSZoneGroupName = '${gpar_customerAbbreviation}-pepdnsgrp-stfsl${gpar_environment != '' ? gpar_environment : 'prod'}001'
var var_pepNetworkInterfaceName = '${gpar_customerAbbreviation}-nic-pep-stfsl${gpar_environment != '' ? gpar_environment : 'prod'}001'

///// ---------------------- STORAGE VARIABLES END ---------------------- ////
///// ---------------------- AVD VARIABLES ---------------------- ///

// Host pool name for the deployment.
var var_vdpoolName = '${gpar_customerAbbreviation}-vdpool-${gpar_environment != '' ? gpar_environment : 'prod'}-${var_locationAVD}-001'

// Application group name and description for Desktop app group.
var var_vdagApplicationGroupType = dpar_vdagApplicationGroupType != '' ? dpar_vdagApplicationGroupType : 'Desktop'
var var_vdagApplicationGroupTypeName = toLower(var_vdagApplicationGroupType)
var var_vdagName = '${gpar_customerAbbreviation}-vdag-${var_vdagApplicationGroupTypeName}-${gpar_environment != '' ? gpar_environment : 'prod'}-${var_locationAVD}-001'
var var_vdagDescription = 'Azure Virtual Desktop Application Group for ${var_vdagName}'

// Workspace name (either provided or default generated).
var var_vdwsName = dpar_vdwsName != '' ? dpar_vdwsName : '${gpar_customerAbbreviation}-vdws-${gpar_environment}-${var_locationAVD}-001'
var var_vdwsDescription = 'Azure Virtual Desktop Workspace for ${var_vdwsName}'

// Session host naming and sizing defaults
var var_vmName = '${gpar_customerAbbreviation}avdwc'
var var_vmCount = dpar_vmCount
var var_vmSize = dpar_vmSize

///// ---------------------- AVD VARIABLES END ---------------------- ////
///// ---------------------- VARIABLES END ---------------------- /////

///// ---------------------- MODULES ---------------------- /////
//// ---------------------- RESOURCE GROUPS ---------------------- ////

// Deploy resource group for AVD resources.
module rgavd '_Modules/resourcegroup/resourcegroup.bicep' = {
  name: var_rgAVDName
  params: {
    rgName: var_rgAVDName
    rgLocation: dpar_location
    rgTags: var_tags
  }
}

// Deploy resource group for storage resources.
module rgstorage '_Modules/resourcegroup/resourcegroup.bicep' = {
  name: var_rgStorageName
  params: {
    rgName: var_rgStorageName
    rgLocation: dpar_location
    rgTags: var_tags
  }
}

// Deploy resource group for networking resources (spoke VNet).
module rgnetwork '_Modules/resourcegroup/resourcegroup.bicep' = {
  name: var_rgNetworkName
  params: {
    rgName: var_rgNetworkName
    rgLocation: dpar_location
    rgTags: var_tags
  }
}

//// ---------------------- RESOURCE GROUPS END ---------------------- ////
//// ---------------------- NETWORKING RESOURCES (SPOKE ONLY) ---------------------- ////

// Create the spoke virtual network. Address space must be supplied explicitly (v2.0.0).
module vnetspokeavd '_Modules/network/virtualnetwork/spokevirtualnetwork.bicep' = {
  name: var_vnetNameSpokeAVD
  scope: resourceGroup(var_rgNetworkName)
  params: {
    vnetName: var_vnetNameSpokeAVD
    vnetLocation: dpar_location
    vnetTags: var_tags
    vnetDnsServers: []
    vnetAddressPrefixes: [dpar_spokeVnetPrefix]
  }
  dependsOn: [
    rgnetwork
  ]
}

// Create the AVD spoke subnet. Subnet prefix must be explicit in v2.0.0.
module snetavd '_Modules/network/subnet/avdsubnet.bicep' = {
  name: spar_snetNameSpokeAVD
  scope: resourceGroup(var_rgNetworkName)
  params: {
    vnetName: vnetspokeavd.outputs.virtualNetworkName
    snetName: spar_snetNameSpokeAVD
    snetAddressPrefixes: dpar_spokeSubnetPrefix
    snetNsgId: nsgdefault.outputs.nsgId
  }
  dependsOn: [
    vnetspokeavd
    nsgdefault
  ]
}

// Create private DNS zone for privatelink resolution (e.g. privatelink.file.core.windows.net).
module privatedns '_Modules/network/privatedns/privatednszones.bicep' = {
  name: dpar_privateDNSName
  scope: resourceGroup(var_rgNetworkName)
  params: {
    dnsZoneName: dpar_privateDNSName
    dnsZoneTags: var_tags
  }
  dependsOn: [
    snetavd
  ]
}

// Create a link between private DNS zone and the spoke VNet.
module privatednslink '_Modules/network/privatedns/privatednslink.bicep' = {
  name: var_privateDNSLinkName
  scope: resourceGroup(var_rgNetworkName)
  params: {
    dnsZoneName: privatedns.outputs.dnsZoneName
    dnsZoneLinkName: var_privateDNSLinkName
    vnetName: vnetspokeavd.outputs.virtualNetworkName
  }
  dependsOn: [
    privatedns
  ]
}

// Default network security group for the spoke/subnet.
module nsgdefault '_Modules/network/nsg/defaultnsg.bicep' = {
  name: var_nsgDefaultName
  scope: resourceGroup(var_rgNetworkName)
  params: {
    nsgName: var_nsgDefaultName
    nsgLocation: dpar_location
    nsgTags: var_tags
  }
  dependsOn: [
    vnetspokeavd
  ]
}

//// ---------------------- NETWORKING RESOURCES END ---------------------- ////
//// ---------------------- STORAGE RESOURCES ---------------------- ////

// Storage account and file share for FSLogix/profile disks.
module storagefslogix '_Modules/storageaccount/filestorage.bicep' = {
  name: var_stName
  scope: resourceGroup(var_rgStorageName)
  params: {
    saName: var_stName
    saLocation: dpar_location
    saTags: var_tags
    fsName: var_stShareName
    fsQuota: var_stShareQuota
    rbacPrincipalUser: dpar_rbacObjectIdRBACAVDUsers
    rbacPrincipalAdmin: dpar_rbacObjectIdRBACAVDAdmin
  }
  dependsOn: [
    rgstorage
  ]
}

// Private endpoint connecting the storage account to the spoke VNet (for FSLogix).
module privateendpointfslogix '_Modules/network/private endpoints/privateendpoint.bicep' = {
  name: var_pepName
  scope: resourceGroup(var_rgNetworkName)
  params: {
    rgName: rgstorage.outputs.resourceGroupName
    pepName: var_pepName
    pepLocation: dpar_location
    pepTags: var_tags
    pepConnectionName: '${var_stName}-to-${var_vmName}'
    vnetName: vnetspokeavd.outputs.virtualNetworkName
    snetName: snetavd.outputs.avdSubnetName
    saName: storagefslogix.outputs.storageAccountName
    pepNicName: var_pepNetworkInterfaceName
  }
  dependsOn: [
    storagefslogix
  ]
}

// Private endpoint DNS zone group linking the privatelink to private DNS zone.
module privateendpointdnszonegroup '_Modules/network/privatedns/privatednszonegroups.bicep' = {
  name: var_privateDNSZoneGroupName
  scope: resourceGroup(var_rgNetworkName)
  params: {
    pepName: var_pepName
    privateDNSName: privatedns.outputs.dnsZoneName
    pepDnsGroupName: var_privateDNSZoneGroupName
  }
  dependsOn: [
    privateendpointfslogix
    privatedns
  ]
}

//// ---------------------- STORAGE RESOURCES END ---------------------- ////
///// ---------------------- AVD-RELATED RESOURCES ---------------------- ////

// Create the AVD host pool (pooled desktop).
module vdpool '_Modules/avd/virtualdesktophostpool.bicep' = {
  name: var_vdpoolName
  scope: resourceGroup(var_rgAVDName)
  params: {
    vdpoolName: var_vdpoolName
    vdpoolLocation: var_locationAVD
    vdpoolTags: var_tags
  }
  dependsOn: [
    rgavd
  ]
}

// Create the AVD Application Group (Desktop) and assign users.
module vdag '_Modules/avd/virtualdesktopapplicationgroup.bicep' = {
  name: var_vdagName
  scope: resourceGroup(var_rgAVDName)
  params: {
    vdagName: var_vdagName
    vdagLocation: var_locationAVD
    vdagTags: var_tags
    vdagDescription: var_vdagDescription
    vdagFriendlyName: var_vdagName
    vdagApplicationGroupType: dpar_vdagApplicationGroupType
    vdpoolArmPath: vdpool.outputs.vdpoolId
    rbacObjectIdUser: dpar_rbacObjectIdFullDesktopUsers
  }
  dependsOn: [
    vdpool
  ]
}

// Create the AVD Workspace and reference the application group.
module vdws '_Modules/avd/virtualdesktopworkspace.bicep' = {
  name: var_vdwsName
  scope: resourceGroup(var_rgAVDName)
  params: {
    vdwsName: var_vdwsName
    vdwsLocation: var_locationAVD
    vdwsTags: var_tags
    vdwsDescription: var_vdwsDescription
    vdwsFriendlyName: var_vdwsName
    vdagReferences: [
      vdag.outputs.vdagId
    ]
  }
  dependsOn: [
    vdag
  ]
}

///// ---------------------- AVD-RELATED RESOURCES END ---------------------- ////
//// ---------------------- SESSION HOSTS ---------------------- ////

// Create session hosts in a loop. Each invocation provisions NIC, VM, extensions and RBAC.
module sessionhosts '_Modules/avd/virtualdesktopsessionhost.bicep' = [
  for host in range(0, var_vmCount): {
    name: '${var_vmName}${host}'
    scope: resourceGroup(var_rgAVDName)
    params: {
      vdpoolName: vdpool.outputs.vdpoolName
      vmName: '${var_vmName}${host}'
      vmLocation: dpar_location
      vmTags: var_tags
      vmNicName: '${var_vmName}${host}-nic-001'
      snetSpokeAVDId: snetavd.outputs.avdSubnetId
      vmlocaladminName: dpar_vmlocaladminName
      vmlocaladminPassword: dpar_vmlocaladminPassword
      vmSize: var_vmSize
      rbacObjectIdUser: dpar_rbacObjectIdRBACAVDUsers
    }
    dependsOn: [
      privatednslink
      vdws
    ]
  }
]

//// ---------------------- SESSION HOSTS END ---------------------- ////
///// ---------------------- MODULES END ---------------------- /////

///// ---------------------- END OF BICEP FILE ---------------------- /////
