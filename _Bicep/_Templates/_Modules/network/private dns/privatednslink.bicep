///// ---------------------- HEADER ---------------------- /////

// Bicep file for deploying a private DNS zone link
// Author: Michele Blum
// Date: 03.08.2024

///// ---------------------- HEADER END ---------------------- /////


///// ---------------------- PARAMETERS ---------------------- /////

// Name of the existing virtual network to which the peering will be added
@description('Name of the existing virtual network to which the peering will be added')
param existingVNETName string

// The name of the private DNS zone to link to the virtual network.
@description('The name of the private DNS zone to link to the virtual network.')
param privateDNSName string

// The name of the virtual network to link to the private DNS zone.
@description('The name of the virtual network to link to the private DNS zone.')
param privateDNSLinkName string

// The location of the private DNS link.
@description('The location of the private DNS link.')
param global string = 'global'

// The registration status of the private DNS link.
@description('The registration status of the private DNS link.')
param registrationEnabled bool = true

///// ---------------------- PARAMETERS END ---------------------- /////


///// ---------------------- RESOURCES ---------------------- /////

// Define the existing 'virtual network' resource
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: existingVNETName
}

// Define the existing 'private DNS zone' resource
resource privatedns 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: privateDNSName
}

// Define the 'private DNS link' resource
resource privatednslink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: privatedns
  name: privateDNSLinkName
  location: global
  properties: {
    registrationEnabled: registrationEnabled
    virtualNetwork: {
      id: vnet.id
    }
  }
}

///// ---------------------- RESOURCES END ---------------------- /////


///// ---------------------- OUTPUTS ---------------------- /////

// Output the name of the private DNS link
output privatednslinkName string = privatednslink.name

// Output the ID of the private DNS link
output privatednslinkId string = privatednslink.properties.virtualNetwork.id

///// ---------------------- OUTPUTS END ---------------------- /////


///// ---------------------- END OF BICEP FILE ---------------------- /////
