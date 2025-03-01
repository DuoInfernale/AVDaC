///// ---------------------- HEADER ---------------------- /////

// Bicep file for deploying a virtual network
// Author: Michele Blum & Flavio Meyer
// Date: 01.03.2025

///// ---------------------- HEADER END ---------------------- /////


///// ---------------------- PARAMETERS ---------------------- /////

// The name of the virtual network.
@description('The name of the virtual network.')
param vnetName string

// The location of the virtual network.
@description('The location of the virtual network.')
param vnetLocation string

// The tags to be assigned to the virtual network.
@description('The tags to be assigned to the virtual network.')
param vnetTags object

// The address prefixes of the virtual network.
@description('The address prefixes of the virtual network.')
param vnetAddressPrefixes string[]

// Indicates whether encryption is enabled for the virtual network.
@description('Indicates whether encryption is enabled for the virtual network.')
param vnetEncryptionEnabled bool = true

// The enforcement mode for encryption.
@description('The enforcement mode for encryption.')
param vnetEncryptionEnforcement string = 'AllowUnencrypted'

// The DNS servers to be configured for the virtual network.
@description('The DNS servers to be configured for the virtual network.')
param vnetDNSServers array = []

///// ---------------------- PARAMETERS END ---------------------- /////


///// ---------------------- RESOURCES ---------------------- /////

// Resource declaration for the virtual network
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
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
      dnsServers: vnetDNSServers
    }
  }
}

///// ---------------------- RESOURCES END ---------------------- /////


///// ---------------------- OUTPUTS ---------------------- /////

// Output the VNet ID and VNet name
output vnetId string = vnet.id
output vnetName string = vnet.name

///// ---------------------- OUTPUTS END ---------------------- /////


///// ---------------------- END OF BICEP FILE ---------------------- /////
