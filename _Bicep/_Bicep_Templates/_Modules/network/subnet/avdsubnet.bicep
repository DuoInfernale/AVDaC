///// ---------------------- HEADER ---------------------- /////

// Bicep file for deploying a subnet into an existing Virtual Network.
//
// Authors: Michele Blum & Flavio Meyer
// Created: 03.08.2024
// Updated: 29.05.2026
// Notes:
// - This module references an existing virtual network and creates (or updates) a subnet under it.
// - If the VNet is in a different resource group, pass vnetRgName accordingly.

///// ---------------------- HEADER END ---------------------- /////

///// ---------------------- CHANGELOG ---------------------- /////

// Version: 1.0.0
// Date: 03.08.2024
// - Initial version
//
// Version: 1.1.0
// Date: 29.05.2026
// - Apply consistent formatting, parameter validation, optional RG scope for existing VNet, and improved outputs

///// ---------------------- CHANGELOG END ---------------------- /////

///// ---------------------- SCOPE ---------------------- /////

// This module is intended to be deployed at resource group scope (subnets are resource-group scoped).
// If calling from a subscription-scoped deployment, call this module with scope: resourceGroup('<rgName>').

///// ---------------------- SCOPE END ---------------------- /////

///// ---------------------- PARAMETERS ---------------------- /////

// Name of the existing virtual network to which the subnet will be added
@description('Name of the existing virtual network to which the subnet will be added.')
@minLength(1)
@maxLength(64)
param vnetName string

// Name of the subnet to be created
@description('Name of the subnet to create under the specified virtual network.')
@minLength(1)
@maxLength(80)
param snetName string

// Address prefixes for the subnet (one or more CIDR ranges)
@description('Address prefixes for the subnet (e.g. [\'10.0.1.0/24\']). Provide at least one prefix.')
param snetAddressPrefixes array

// Resource ID of the Network Security Group to associate with the subnet (optional)
@description('Resource ID of the network security group to associate with the subnet. Leave empty to not associate an NSG.')
param snetNsgId string = ''

// Default outbound access is disabled for subnets in Azure Virtual Desktop host pools, so we set it to false by default and do not expose it as a parameter.
@description('Default outbound access is disabled for subnets in Azure Virtual Desktop host pools, so this is set to false by default and not exposed as a parameter.')
param defaultOutboundAccess bool = true

///// ---------------------- PARAMETERS END ---------------------- /////

///// ---------------------- RESOURCES ---------------------- /////

// Reference existing Virtual Network (may be in another resource group if vnetRgName is provided)
resource virtualnetwork_module 'Microsoft.Network/virtualNetworks@2025-05-01' existing = {
  name: vnetName
}

// Subnet resource under the existing VNet
resource subnet_module 'Microsoft.Network/virtualNetworks/subnets@2025-05-01' = {
  name: snetName
  parent: virtualnetwork_module
  properties: {
    addressPrefixes: snetAddressPrefixes
    networkSecurityGroup: empty(snetNsgId) ? null : {
      id: snetNsgId
    }
    defaultOutboundAccess: defaultOutboundAccess
  }
  dependsOn: [
    virtualnetwork_module
  ]
}

///// ---------------------- RESOURCES END ---------------------- /////

///// ---------------------- OUTPUTS ---------------------- /////

// Subnet resource ID
output avdSubnetId string = subnet_module.id

// Subnet name
output avdSubnetName string = subnet_module.name

// Subnet address prefixes (as deployed)
output avdSubnetAddressPrefixes array = subnet_module.properties.addressPrefixes

// Associated NSG id (may be null/empty if none)
output avdSubnetNsgId string = subnet_module.properties.networkSecurityGroup != null ? subnet_module.properties.networkSecurityGroup.id : ''

///// ---------------------- OUTPUTS END ---------------------- /////
