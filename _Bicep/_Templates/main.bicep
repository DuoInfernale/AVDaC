///// ---------------------- HEADER ---------------------- /////

// Main Bicep template for the deployment of an Azure Virtual Desktop (AVD) environment.
// This template deploys the following resources:
// - Resource groups
// - Virtual networks
// - Subnets
// - Peering
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
 
// Authors: Michele Blum & Flavio Meyer
// Creation date: 01.03.2025

///// ---------------------- HEADER END ---------------------- /////


///// ---------------------- CHANGELOG ---------------------- /////

// Version: 1.0.0
// Date: 01.03.2025
// Changes:
// - Initial version

///// ---------------------- CHANGELOG END ---------------------- /////


///// ---------------------- SCOPE ---------------------- /////

// Define the scope for the deployment.
// In this case, the deployment is scoped to a subscription.
// The subscription will be defined by the access of the service principal.
targetScope = 'subscription'

///// ---------------------- SCOPE END ---------------------- /////


///// ---------------------- PARAMETERS ---------------------- /////
//// ---------------------- GLOBAL PARAMETERS ---------------------- ////

// The abbreviation of the customer for the deployment.
param gpar_customerAbbreviation string

// The environment for the deployment (e.g., dev, test, prod).
param gpar_environment string

// Tags to be applied to the resources for resource management and organization.
param gpar_tags object

//// ---------------------- GLOBAL PARAMETERS END ---------------------- ////
//// ---------------------- STATIC PARAMETERS ---------------------- ////

// The network ID for the deployment (CIDR).
param spar_vnetCIDR int = 22

// The CIDR for the hub subnet.
param spar_snetHubCIDR int = 26

// The CIDR for the spoke AVD subnet.
param spar_snetSpokeAVDCIDR int = 24

// The name of the spoke AVD subnet.
param spar_snetNameSpokeAVD string = 'AVDSubnet'

//// ---------------------- STATIC PARAMETERS END ---------------------- ////
//// ---------------------- DYNAMIC PARAMETERS ---------------------- ////

// The location for the deployment.
param dpar_location string

// The location for the AVD deployment.
param dpar_locationAVD string

// The network ID for the deployment.
param dpar_networkId string

// The name of the AVD workspace.
param dpar_vdwsName string

// The quota for the file share.
param dpar_fsshareQuota int

// The count of the virtual machines.
param dpar_vmCount int

// The size of the virtual machine.
param dpar_vmSize string

// The name of the private DNS zone.
param dpar_privateDNSName string

// The name of the local admin for the virtual machines.
param dpar_vmlocaladminName string

// The password of the local admin for the virtual machines.
@secure()
param dpar_vmlocaladminPassword string

// The object ID for the full desktop users.
param dpar_rbacObjectIdFullDesktopUsers string

// The object ID for the AVD users.
param dpar_rbacObjectIdRBACAVDUsers string

// The object ID for the AVD admin.
param dpar_rbacObjectIdRBACAVDAdmin string

//// ---------------------- DYNAMIC PARAMETERS END ---------------------- ////
///// ---------------------- PARAMETERS END ---------------------- /////


///// ---------------------- VARIABLES ---------------------- /////
///// ---------------------- BASIC VARIABLES ---------------------- ////

// If the tags are not provided, the default values will be used.
// The defaults are the environment 'prod' and the customer abbreviation 'duo'.
var var_tags = gpar_tags != {}
  ? gpar_tags
  : {
      Environment: gpar_environment != '' ? gpar_environment : 'prod'
      Customer: gpar_customerAbbreviation != '' ? gpar_customerAbbreviation : 'duo'
    }

// Definition of the resource group names.
// If no values are provided, the defaults are the environment 'prod' 
// and the location 'switzerlandnorth'.
// This definition is for the resource group of the AVD resources.
var var_rgAVDName = '${gpar_customerAbbreviation}-rg-avd-${gpar_environment != '' ? gpar_environment : 'prod'}-${dpar_location != '' ? dpar_location : 'switzerlandnorth'}-001'

// This definition is for the resource group of the storage resources.
var var_rgStorageName = '${gpar_customerAbbreviation}-rg-storage-${gpar_environment != '' ? gpar_environment : 'prod'}-${dpar_location != '' ? dpar_location : 'switzerlandnorth'}-001'

// This definition is for the resource group of the network resources.
var var_rgNetworkName = '${gpar_customerAbbreviation}-rg-network-${gpar_environment != '' ? gpar_environment : 'prod'}-${dpar_location != '' ? dpar_location : 'switzerlandnorth'}-001'

///// ---------------------- BASIC VARIABLES END ---------------------- ////
///// ---------------------- NETWORKING VARIABLES ---------------------- ////

// Definition of the virtual network names.
// If no values are provided, the defaults are the environment 'prod' 
// and the location 'switzerlandnorth'.
// This definition is for the virtual network of the hub.
var var_vnetNameHub = '${gpar_customerAbbreviation}-vnet-hub-${gpar_environment != '' ? gpar_environment : 'prod'}-${dpar_location != '' ? dpar_location : 'switzerlandnorth'}-001'

// This definition is for the virtual network of the spoke AVD.
var var_vnetNameSpokeAVD = '${gpar_customerAbbreviation}-vnet-spoke-avd-${gpar_environment != '' ? gpar_environment : 'prod'}-${dpar_location != '' ? dpar_location : 'switzerlandnorth'}-001'

// Calculation of the subnets for the virtual networks.
var var_vnetCalculations = [
  for i in range(0, 2): cidrSubnet(dpar_networkId != '' ? dpar_networkId : '10.100.0.0/20', spar_vnetCIDR, i)
]

// Calculation of the subnets for the hub.
var var_snetCalculationsHub = [for i in range(0, 16): cidrSubnet(var_vnetCalculations[0], spar_snetHubCIDR, i)]

// Calculation of the subnets for the spoke AVD.
var var_snetCalculationsSpokeAVD = [for i in range(0, 2): cidrSubnet(var_vnetCalculations[1], spar_snetSpokeAVDCIDR, i)]

// Definition of the default addresses for the hub subnets.
// The default addresses are the AzureFirewallSubnet, GatewaySubnet, AzureBastionSubnet, and FirewallSubnet.
var var_hubsnetdefaultaddresses = [
  {
    name: 'AzureFirewallSubnet'
    prefix: var_snetCalculationsHub[0]
  }
  {
    name: 'GatewaySubnet'
    prefix: var_snetCalculationsHub[4]
  }
  {
    name: 'AzureBastionSubnet'
    prefix: var_snetCalculationsHub[8]
  }
  {
    name: 'FirewallSubnet'
    prefix: var_snetCalculationsHub[12]
  }
]

// Definition of the peering names.
// This definition is for the peering of the hub.
var var_peerHubName = '${gpar_customerAbbreviation}-peer-hub-${gpar_environment != '' ? gpar_environment : 'prod'}'

// This definition is for the peering of the spoke AVD.
var var_peerSpokeAVDName = '${gpar_customerAbbreviation}-peer-spoke-avd-${gpar_environment != '' ? gpar_environment : 'prod'}'

// Definition of the private DNS link name.
var var_privateDNSLinkName = '${gpar_customerAbbreviation}-pl-${var_vnetNameSpokeAVD}'

// Definition of the NSG names.
// This definition is for the default NSG.
var var_nsgDefaultName = '${gpar_customerAbbreviation}-nsg-default-${gpar_environment != '' ? gpar_environment : 'prod'}-${dpar_location != '' ? dpar_location : 'switzerlandnorth'}-001'

// This definition is for the Bastion NSG.
var var_nsgBastionName = '${gpar_customerAbbreviation}-nsg-bastion-${gpar_environment != '' ? gpar_environment : 'prod'}-${dpar_location != '' ? dpar_location : 'switzerlandnorth'}-001'

// Definition of the association name for the Bastion NSG.
var var_bastionsubnetnsgaassociationName = '${gpar_customerAbbreviation}-bastionsubnetnsgaassociation-${gpar_environment != '' ? gpar_environment : 'prod'}-${dpar_location != '' ? dpar_location : 'switzerlandnorth'}-001'

// Definition of the private Endpoint name.
var var_pepName = '${gpar_customerAbbreviation}-pep-stfsl${gpar_environment != '' ? gpar_environment : 'prod'}001'

// Definition of the private DNS zone group name.
var var_privateDNSZoneGroupName = '${gpar_customerAbbreviation}-pepdnsgrp-stfsl${gpar_environment != '' ? gpar_environment : 'prod'}001'

// Definition of the private Endpoint connection name.
var var_pepConnectionName = '${var_stName}-to-${var_vmName}'

// Definition of the private Endpoint network interface name.
var var_pepNetworkInterfaceName = '${gpar_customerAbbreviation}-nic-pep-stfsl${gpar_environment != '' ? gpar_environment : 'prod'}001'

///// ---------------------- NETWORKING VARIABLES END ---------------------- ////
/// ---------------------- AVD VARIABLES ---------------------- ///

// Definition of the AVD pool name.
var var_vdpoolName = '${gpar_customerAbbreviation}-vdpool-${gpar_environment != '' ? gpar_environment : 'prod'}-${dpar_location != '' ? dpar_location : 'switzerlandnorth'}-001'

// Definition of the AVD application group name.
var var_vdagName = '${gpar_customerAbbreviation}-vdag-desktop-${gpar_environment != '' ? gpar_environment : 'prod'}-${dpar_location != '' ? dpar_location : 'switzerlandnorth'}-001'

// Description of the AVD application group.
var var_vdagDescription = 'Azure Virtual Desktop Application Group for ${var_vdagName}'

// AVD workspace name, with optional default value.
var var_vdwsName = dpar_vdwsName != ''
  ? dpar_vdwsName
  : '${gpar_customerAbbreviation}-vdws-${gpar_environment}-${var_locationAVD}-001'

// Description of the AVD workspace.
var var_vdwsDescription = 'Azure Virtual Desktop Workspace for ${var_vdwsName}'

// Location for the AVD deployment with a default value.
var var_locationAVD = dpar_locationAVD != '' ? dpar_locationAVD : 'westeurope'

// Definition of the AVD session host name.
var var_vmName = '${gpar_customerAbbreviation}avd${gpar_environment}'

// Default count of virtual machines.
var var_vmCount = dpar_vmCount != '' ? dpar_vmCount : 2

// Default size of the virtual machine.
var var_vmSize = dpar_vmSize != '' ? dpar_vmSize : 'Standard_D2as_v5'

/// ---------------------- AVD VARIABLES END ---------------------- ///
//// ---------------------- STORAGE VARIABLES ---------------------- ////

// Definition of the storage account name.
var var_stName = '${gpar_customerAbbreviation}stfsl${gpar_environment != '' ? gpar_environment : 'prod'}001'

// Name of the file share for storage.
var var_stShareName = 'fslogix'

// Quota for the file share with a default value.
var var_stShareQuota = dpar_fsshareQuota != '' ? dpar_fsshareQuota : 1024

//// ---------------------- STORAGE VARIABLES END ---------------------- ////
///// ---------------------- VARIABLES END ---------------------- /////


///// ---------------------- MODULES ---------------------- /////
//// ---------------------- RESOURCE GROUPS ---------------------- ////

// Defines the AVD resource group.
module rgavd '_Modules/resourcegroup/rg.bicep' = {
  name: var_rgAVDName
  params: {
    rgName: var_rgAVDName
    rgLocation: dpar_location
    rgTags: var_tags
  }
}

// Defines the storage resource group.
module rgstorage '_Modules/resourcegroup/rg.bicep' = {
  name: var_rgStorageName
  params: {
    rgName: var_rgStorageName
    rgLocation: dpar_location
    rgTags: var_tags
  }
}

// Defines the network resource group.
module rgnetwork '_Modules/resourcegroup/rg.bicep' = {
  name: var_rgNetworkName
  params: {
    rgName: var_rgNetworkName
    rgLocation: dpar_location
    rgTags: var_tags
  }
}

//// ---------------------- RESOURCE GROUPS END ---------------------- ////
//// ---------------------- NETWORKING RESOURCES ---------------------- ////

// Defines the virtual network for the hub.
module vnethub '_Modules/network/vnet.bicep' = {
  name: var_vnetNameHub
  scope: resourceGroup(var_rgNetworkName)
  params: {
    vnetName: var_vnetNameHub
    vnetLocation: dpar_location
    vnetTags: gpar_tags
    vnetAddressPrefixes: [var_vnetCalculations[0]]
  }
  dependsOn: [
    rgnetwork
  ]
}

// Defines the subnet for the hub.
@batchSize(1)
module snethub '_Modules/network/snethub.bicep' = [
  for snetHub in var_hubsnetdefaultaddresses: {
    name: snetHub.name
    scope: resourceGroup(var_rgNetworkName)
    params: {
      existingVNETName: vnethub.outputs.vnetName
      snetName: snetHub.name
      snetAddressPrefixes: snetHub.prefix
    }
  }
]

// Defines the virtual network for the AVD spoke.
module vnetspokeavd '_Modules/network/vnet.bicep' = {
  name: var_vnetNameSpokeAVD
  scope: resourceGroup(var_rgNetworkName)
  params: {
    vnetName: var_vnetNameSpokeAVD
    vnetLocation: dpar_location
    vnetTags: gpar_tags
    vnetAddressPrefixes: [var_vnetCalculations[1]]
  }
  dependsOn: [
    rgnetwork
  ]
}

// Defines the subnet for the AVD spoke.
module snetavd '_Modules/network/snetspoke.bicep' = {
  name: spar_snetNameSpokeAVD
  scope: resourceGroup(var_rgNetworkName)
  params: {
    existingVNETName: vnetspokeavd.outputs.vnetName
    snetName: spar_snetNameSpokeAVD
    snetAddressPrefixes: var_snetCalculationsSpokeAVD[0]
    snetNSGId: nsgdefault.outputs.defaultNSGId
  }
}

// Defines the peering for the hub.
module hubpeer '_Modules/network/peer.bicep' = {
  name: var_peerHubName
  scope: resourceGroup(var_rgNetworkName)
  params: {
    existingVNETName: vnethub.outputs.vnetName
    peerName: var_peerSpokeAVDName
    peerAllowForwardedTraffic: true
    peerAllowVirtualNetworkAccess: true
    vnetId: vnetspokeavd.outputs.vnetId
  }
  dependsOn: [
    snetavd
  ]
}

// Defines the peering for the AVD spoke.
module peerspokeavd '_Modules/network/peer.bicep' = {
  name: var_peerSpokeAVDName
  scope: resourceGroup(var_rgNetworkName)
  params: {
    existingVNETName: vnetspokeavd.outputs.vnetName
    peerName: var_peerHubName
    peerAllowForwardedTraffic: true
    peerAllowVirtualNetworkAccess: true
    vnetId: vnethub.outputs.vnetId
  }
  dependsOn: [
    hubpeer
  ]
}

// Defines the private DNS zone.
module privatedns '_Modules/network/private dns/privatedns.bicep' = {
  name: dpar_privateDNSName
  scope: resourceGroup(var_rgNetworkName)
  params: {
    privateDNSName: dpar_privateDNSName
    privateDNSTags: gpar_tags
  }
  dependsOn: [
    peerspokeavd
  ]
}

// Defines the private DNS link.
module privatednslink '_Modules/network/private dns/privatednslink.bicep' = {
  name: var_privateDNSLinkName
  scope: resourceGroup(var_rgNetworkName)
  params: {
    privateDNSName: privatedns.outputs.privateDNSName
    privateDNSLinkName: var_privateDNSLinkName
    existingVNETName: vnetspokeavd.outputs.vnetName
  }
}


// Defines the default network security group
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

// Defines the network security group for the Azure Bastion.
module nsgbastion '_Modules/network/nsg/bastionnsg.bicep' = {
  name: var_nsgBastionName
  scope: resourceGroup(var_rgNetworkName)
  params: {
    nsgName: var_nsgBastionName
    nsgLocation: dpar_location
    nsgTags: var_tags
  }
  dependsOn: [
    vnetspokeavd
  ]
}

// Defines the network security group for the Azure Bastion.
module bastionsubnetnsgaassociation '_Modules/network/snetbastion.bicep' = {
  name: var_bastionsubnetnsgaassociationName
  scope: resourceGroup(var_rgNetworkName)
  params: {
    existingVNETName: vnethub.outputs.vnetName
    snetName: var_hubsnetdefaultaddresses[2].name
    properties: {
      addressPrefix: var_hubsnetdefaultaddresses[2].prefix
      networkSecurityGroup: {
        id: nsgbastion.outputs.bastionNSGId
      }
    }
  }
  dependsOn: [
    snethub
  ]
}

//// ---------------------- NETWORKING RESOURCES END ---------------------- ////
//// ---------------------- STORAGE RESOURCES ---------------------- ////

// Defines the storage account.
module storagefslogix '_Modules/storage/azfiles.bicep' = {
  name: var_stName
  scope: resourceGroup(var_rgStorageName)
  params: {
    stName: var_stName
    stLocation: dpar_location
    stTags: var_tags
    shareName: var_stShareName
    shareQuota: var_stShareQuota
    rbacObjectIdUser: dpar_rbacObjectIdRBACAVDUsers
    rbacObjectIdAdmin: dpar_rbacObjectIdRBACAVDAdmin
  }
  dependsOn: [
    rgstorage
  ]
}

// Defines the private endpoint for the storage account.
module privateendpointfslogix '_Modules/network/private endpoints/pep.bicep' = {
  name: var_pepName
  scope: resourceGroup(var_rgNetworkName)
  params: {
    rgName: rgstorage.outputs.rgName
    pepName: var_pepName
    pepLocation: dpar_location
    pepTags: var_tags
    pepConnectionName: var_pepConnectionName
    vnetName: vnetspokeavd.outputs.vnetName
    subnetName: snetavd.outputs.snetName
    storageAccountName: storagefslogix.outputs.storageAccountName
    pepCustomNetworkInterfaceName: var_pepNetworkInterfaceName
  }
}

// Defines the private DNS zone group.
module privateendpointdnszonegroup '_Modules/network/private endpoints/pepdnszone.bicep' = {
  name: var_privateDNSZoneGroupName
  scope: resourceGroup(var_rgNetworkName)
  params: {
    pepName: var_pepName
    privateDNSName: privatedns.outputs.privateDNSName
    pepDnsGroupName: var_privateDNSZoneGroupName
  }
  dependsOn: [
    privateendpointfslogix
  ]
}

//// ---------------------- STORAGE RESOURCES END ---------------------- ////
///// ---------------------- AVD-RELATED RESOURCES ---------------------- ////

// Defines the AVD host pool.
module vdpool '_Modules/avd/vdpooldesktop.bicep' = {
  name: var_vdpoolName
  scope: resourceGroup(var_rgAVDName)
  params: {
    vdpoolName: var_vdpoolName
    vdpoolLocation: dpar_locationAVD
    vdpoolTags: gpar_tags
  }
  dependsOn: [
    rgavd
  ]
}

// Defines the AVD application group.
module vdag '_Modules/avd/vdagdesktop.bicep' = {
  name: var_vdagName
  scope: resourceGroup(var_rgAVDName)
  params: {
    vdagName: var_vdagName
    vdagLocation: var_locationAVD
    vdagTags: var_tags
    vdagDescription: var_vdagDescription
    vdagFriendlyName: var_vdagName
    vdpoolId: vdpool.outputs.vdpoolId
    rbacObjectIdUser: dpar_rbacObjectIdFullDesktopUsers
  }
}

// Defines the AVD workspace.
module vdws '_Modules/avd/vdws.bicep' = {
  name: var_vdwsName
  scope: resourceGroup(var_rgAVDName)
  params: {
    vdwsName: var_vdwsName
    vdwsLocation: var_locationAVD
    vdwsTags: var_tags
    vdwsDescription: var_vdwsDescription
    vdwsFriendlyName: var_vdwsName
    vdagReferences: vdag.outputs.vdagId
  }
}

///// ---------------------- AVD-RELATED RESOURCES END ---------------------- ////
//// ---------------------- SESSION HOSTS ---------------------- ////

// Defines the AVD session hosts.
module sessionhosts '_Modules/avd/sessionhost.bicep' = [
  for host in range(0, var_vmCount): {
    name: '${var_vmName}${host}'
    scope: resourceGroup(var_rgAVDName)
    params: {
      vdpoolName: vdpool.outputs.vdpoolName
      vmName: '${var_vmName}${host}'
      vmLocation: dpar_location
      vmTags: var_tags
      vmNicName: '${var_vmName}${host}-nic-001'
      snetSpokeAVDId: snetavd.outputs.snetid
      vmlocaladminName: dpar_vmlocaladminName
      vmlocaladminPassword: dpar_vmlocaladminPassword
      vmSize: var_vmSize
      rbacObjectIdUser: dpar_rbacObjectIdRBACAVDUsers
    }
    dependsOn: [
      privatednslink
    ]
  }
]

//// ---------------------- SESSION HOSTS END ---------------------- ////
///// ---------------------- MODULES END ---------------------- /////


///// ---------------------- END OF BICEP FILE ---------------------- /////
