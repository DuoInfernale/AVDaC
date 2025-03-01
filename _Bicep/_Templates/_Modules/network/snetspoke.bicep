// Bicep file for deploying a network subnet for a spoke virtual network
// Author: Michele Blum
// Date: 03.08.2024

/// ---------------------- Parameters ---------------------- ///
// Name of the existing virtual network to which the subnet will be added
@description('Name of the existing virtual network to which the subnet will be added')
param existingVNETName string

// Name of the subnet to be created
@description('Name of the subnet to be created')
param snetName string

// Address prefixes for the subnet
@description('Address prefixes for the subnet')
param snetAddressPrefixes string

// Resource ID of the network security group to associate with the subnet
@description('Resource ID of the network security group to associate with the subnet')
param snetNSGId string

/// ---------------------- Parameters End ---------------------- ///

/// ---------------------- Resource ---------------------- ///
// Define the existing 'virtual network' resource
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: existingVNETName
}

// Define the 'subnet' resource
resource snet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  name: snetName
  parent: vnet
  properties: {
    addressPrefixes: [
      snetAddressPrefixes
    ]
    networkSecurityGroup: {
      id: snetNSGId
    }
  }
}

/// ---------------------- Resource End ---------------------- ///

/// ---------------------- Outputs ---------------------- ///
// Output the resource ID of the created subnet
output snetid string = snet.id

// Output the name of the created subnet
output snetName string = snet.name

/// ---------------------- Outputs End ---------------------- ///

/// ---------------------- End of Bicep file  ---------------------- ///
