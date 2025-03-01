///// ---------------------- HEADER ---------------------- /////

// Bicep file for deploying a network peering
// Author: Michele Blum & Flavio Meyer
// Date: 01.03.2025

///// ---------------------- HEADER END ---------------------- /////


///// ---------------------- PARAMETERS ---------------------- /////

// Name of the existing virtual network to which the peering will be added
@description('Name of the existing virtual network to which the peering will be added')
param existingVNETName string

// Name of the peering connection
@description('Name of the peering connection')
param peerName string

// Boolean flag to allow forwarded traffic in the peering connection
@description('Boolean flag to allow forwarded traffic in the peering connection')
param peerAllowForwardedTraffic bool

// Boolean flag to allow virtual network access in the peering connection
@description('Boolean flag to allow virtual network access in the peering connection')
param peerAllowVirtualNetworkAccess bool

// Resource ID of the remote virtual network to peer with
@description('Resource ID of the remote virtual network to peer with')
param vnetId string

///// ---------------------- PARAMETERS END ---------------------- /////


///// ---------------------- RESOURCES ---------------------- /////

// Define the existing 'virtual network' resource
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: existingVNETName
}

// Define the 'peer' resource
resource peer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  name: peerName
  parent: vnet
  properties: {
    allowForwardedTraffic: peerAllowForwardedTraffic
    allowVirtualNetworkAccess: peerAllowVirtualNetworkAccess
    remoteVirtualNetwork: {
      id: vnetId
    }
  }
}

///// ---------------------- RESOURCES END ---------------------- /////


///// ---------------------- OUTPUTS ---------------------- /////
/// ---------------------- OUTPUTS END ---------------------- /////


///// ---------------------- END OF BICEP FILE ---------------------- /////
