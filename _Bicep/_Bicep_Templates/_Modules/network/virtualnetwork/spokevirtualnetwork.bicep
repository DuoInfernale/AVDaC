///// ---------------------- HEADER ---------------------- /////

// Bicep file for deploying a Virtual Network.
//
// Authors: Michele Blum & Flavio Meyer
// Created: 01.03.2025
// Updated: 29.05.2026
// Notes:
// - This module creates a virtual network with address space, optional DNS servers and encryption settings.
// - Deploy this module at resource group scope (virtual networks are resource-group scoped).

///// ---------------------- HEADER END ---------------------- /////

///// ---------------------- CHANGELOG ---------------------- /////

// Version: 1.0.0
// Date: 01.03.2025
// - Initial version
//
// Version: 1.1.0
// Date: 14.05.2026
// - Added additional properties and defaults
//
// Version: 1.2.0
// Date: 29.05.2026
// - Apply consistent formatting, parameter validation and outputs

///// ---------------------- CHANGELOG END ---------------------- /////

///// ---------------------- PARAMETERS ---------------------- /////

// Virtual Network name
@description('Name of the virtual network to create.')
@minLength(2)
@maxLength(64)
param vnetName string

// Azure region where the VNet will be deployed
@description('Azure region where the virtual network will be created (for example: westeurope).')
@minLength(1)
@maxLength(64)
param vnetLocation string

// Tags applied to the VNet (optional)
@description('Tags to apply to the virtual network.')
param vnetTags object = {}

// VNet address prefixes (one or more CIDR ranges)
@description('List of address prefixes for the virtual network (e.g. [\'10.0.0.0/16\']). Provide at least one prefix.')
param vnetAddressPrefixes array

// Enable VNet encryption
@description('Enable encryption of traffic between subnets (when supported).')
param vnetEncryptionEnabled bool = true

// Encryption enforcement mode (AllowUnencrypted or DropUnencrypted)
@description('Encryption enforcement mode for VNet encryption.')
@allowed([
  'AllowUnencrypted'
  'DropUnencrypted'
])
param vnetEncryptionEnforcement string = 'AllowUnencrypted'

// Custom DNS server list (optional)
@description('List of custom DNS server IP addresses to configure on the VNet DHCP options (optional).')
param vnetDnsServers array = []

///// ---------------------- PARAMETERS END ---------------------- /////


///// ---------------------- RESOURCES ---------------------- /////

// Virtual Network
resource virtualnetwork_module 'Microsoft.Network/virtualNetworks@2025-05-01' = {
  name: vnetName
  location: vnetLocation
  tags: vnetTags

  properties: {
    addressSpace: {
      addressPrefixes: vnetAddressPrefixes
    }

    encryption: {
      enabled: vnetEncryptionEnabled
      enforcement: vnetEncryptionEnforcement
    }

    dhcpOptions: {
      dnsServers: vnetDnsServers
    }
  }
}

///// ---------------------- RESOURCES END ---------------------- /////


///// ---------------------- OUTPUTS ---------------------- /////

// Virtual Network ID
output virtualNetworkId string = virtualnetwork_module.id

// Virtual Network name
output virtualNetworkName string = virtualnetwork_module.name

// Virtual Network address prefixes
output virtualNetworkAddressPrefixes array = virtualnetwork_module.properties.addressSpace.addressPrefixes

// DNS servers configured on the VNet (may be empty)
output virtualNetworkDnsServers array = virtualnetwork_module.properties.dhcpOptions.dnsServers

///// ---------------------- OUTPUTS END ---------------------- /////
