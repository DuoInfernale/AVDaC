///// ---------------------- HEADER ---------------------- /////

// Bicep file for deploying a Private DNS Zone Virtual Network Link.
//
// Authors: Michele Blum & Flavio Meyer
// Created: 03.08.2024
// Updated: 29.05.2026
// Notes:
// - Links an existing virtual network to an existing private DNS zone.
// - This module must be deployed at resource group scope (private DNS zone links are RG-scoped).
// - If the virtual network is in a different resource group, provide vnetRgName to reference it.

///// ---------------------- HEADER END ---------------------- /////

///// ---------------------- CHANGELOG ---------------------- /////

// Version: 1.0.0
// Date: 03.08.2024
// - Initial version
//
// Version: 1.1.0
// Date: 29.05.2026
// - Apply consistent formatting, parameter validation, optional VNet RG scope and additional outputs

///// ---------------------- CHANGELOG END ---------------------- /////

///// ---------------------- SCOPE ---------------------- /////

// Module is intended to be deployed at resource group scope
targetScope = 'resourceGroup'

///// ---------------------- SCOPE END ---------------------- /////

///// ---------------------- PARAMETERS ---------------------- /////

// Resource group that contains the existing Virtual Network (defaults to current deployment RG)
@description('Resource group name that contains the existing virtual network. Defaults to the current deployment resource group.')
param vnetRgName string = resourceGroup().name

// Existing Virtual Network name to link to the private DNS zone
@description('Name of the existing virtual network to link to the private DNS zone.')
@minLength(1)
@maxLength(64)
param vnetName string

// Existing Private DNS Zone name (e.g. privatelink.file.core.windows.net)
@description('Name of the existing private DNS zone to link (e.g. privatelink.file.core.windows.net).')
@minLength(1)
@maxLength(255)
param dnsZoneName string

// Desired name of the virtual network link (child resource name)
@description('The name to use for the private DNS zone virtual network link.')
@minLength(1)
@maxLength(80)
param dnsZoneLinkName string

// Location (private DNS link resources are deployed with location "global")
@description('The location for the private DNS zone link. Use "global".')
param dnsZoneLocation string = 'global'

// Enable auto-registration of DNS records for this VNet
@description('Enables auto-registration of DNS records for this Virtual Network when set to true.')
param registrationEnabled bool = true

///// ---------------------- PARAMETERS END ---------------------- /////

///// ---------------------- RESOURCES ---------------------- /////

// Reference existing Virtual Network (may reside in a different resource group)
resource virtualnetwork_module 'Microsoft.Network/virtualNetworks@2025-05-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetRgName)
}

// Reference existing Private DNS Zone (must exist in the deployment RG or be referenced appropriately)
resource privatednszone_module 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: dnsZoneName
}

// Private DNS Zone Virtual Network Link (child resource of the Private DNS Zone)
resource privatednszonelink_module 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  name: dnsZoneLinkName
  parent: privatednszone_module
  location: dnsZoneLocation
  properties: {
    registrationEnabled: registrationEnabled
    virtualNetwork: {
      id: virtualnetwork_module.id
    }
  }
  dependsOn: [
    privatednszone_module
  ]
}

///// ---------------------- RESOURCES END ---------------------- /////

///// ---------------------- OUTPUTS ---------------------- /////

// Resource ID of the created Private DNS Zone Virtual Network Link
output privateDnsZoneLinkId string = privatednszonelink_module.id

// Name of the created Private DNS Zone Virtual Network Link
output privateDnsZoneLinkName string = privatednszonelink_module.name

// The ID of the linked Virtual Network
output linkedVirtualNetworkId string = virtualnetwork_module.id

// Effective registrationEnabled value for the link
output registrationEnabledOutput bool = privatednszonelink_module.properties.registrationEnabled

///// ---------------------- OUTPUTS END ---------------------- /////
