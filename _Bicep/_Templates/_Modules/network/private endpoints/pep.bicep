///// ---------------------- HEADER ---------------------- /////

// Bicep file for deploying a private endpoint to a storage account (file share)
// Author: Michele Blum & Flavio Meyer
// Date: 01.03.2025

///// ---------------------- HEADER END ---------------------- /////


///// ---------------------- PARAMETERS ---------------------- /////

// The name of the resource group to be used.
@description('The name of the resource group to be used.')
param rgName string

// The name of the virtual network to be used.
@description('The name of the virtual network to be used.')
param vnetName string

// The name of the subnet to be used.
@description('The name of the subnet to be used.')
param subnetName string

// The name of the storage account to be used.
@description('The name of the storage account to be used.')
param storageAccountName string

// The name of the private endpoint to be created.
@description('The name of the private endpoint to be created.')
param pepName string

// The location of the private endpoint.
@description('The location of the private endpoint.')
param pepLocation string

// Tags to be applied to the private endpoint for resource management and organization.
@description('Tags to be applied to the private endpoint.')
param pepTags object

// The name of the private endpoint connection.
@description('The name of the private endpoint connection.')
param pepConnectionName string

// The name of the custom network interface.
@description('The name of the custom network interface.')
param pepCustomNetworkInterfaceName string

// The group ID for the private link service connection.
@description('The group ID for the private link service connection.')
param groupId string = 'file'

// The status of the private link service connection.
@description('The status of the private link service connection.')
param status string = 'Approved'

// The actions required for the private link service connection.
@description('The actions required for the private link service connection.')
param actionsRequired string = 'None'

///// ---------------------- PARAMETERS END ---------------------- /////


///// ---------------------- RESOURCES ---------------------- /////

// Define the existing 'virtual network' resource
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: vnetName
}

// Define the existing 'subnet' resource
resource snet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  name: subnetName
  parent: vnet
}

// Define the existing 'storage account' resource
resource fsstorageaccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
  scope: resourceGroup(rgName)
}

// Define the 'private endpoint' resource
resource pep 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: pepName
  location: pepLocation
  tags: pepTags
  properties: {
    subnet: {
      id: snet.id
    }
    customNetworkInterfaceName: pepCustomNetworkInterfaceName
    privateLinkServiceConnections: [
      {
        name: pepConnectionName
        properties: {
          privateLinkServiceId: fsstorageaccount.id
          groupIds: [
            groupId
          ]
          privateLinkServiceConnectionState: {
            status: status
            actionsRequired: actionsRequired
          }
        }
      }
    ]
  }
}

///// ---------------------- RESOURCES END ---------------------- /////


///// ---------------------- OUTPUTS ---------------------- /////
/// ---------------------- OUTPUTS END ---------------------- /////


///// ---------------------- END OF BICEP FILE ---------------------- /////
