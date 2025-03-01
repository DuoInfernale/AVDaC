///// ---------------------- HEADER ---------------------- /////

// Bicep file for updating the Azure Bastion network subnet for a hub virtual network
// Author: Michele Blum & Flavio Meyer
// Date: 01.03.2025

///// ---------------------- HEADER END ---------------------- /////


///// ---------------------- PARAMETERS ---------------------- /////

// Name of the existing virtual network to which the subnet will be added
@description('Name of the existing virtual network to which the subnet will be added')
param existingVNETName string

// Name of the subnet to be created
@description('Name of the subnet to be created')
param snetName string

// Properties for the subnet
@description('Properties for the subnet')
param properties object

///// ---------------------- PARAMETERS END ---------------------- /////


///// ---------------------- RESOURCES ---------------------- /////

// Define the existing 'virtual network' resource
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: existingVNETName
}

// Define the existing 'subnet' resource
resource snet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  name: snetName
  parent: vnet
  properties: properties
}

///// ---------------------- RESOURCES END ---------------------- /////


///// ---------------------- OUTPUTS ---------------------- /////

// Output the resource ID of the created subnet
output snetid string = snet.id

///// ---------------------- OUTPUTS END ---------------------- /////


///// ---------------------- END OF BICEP FILE ---------------------- /////
