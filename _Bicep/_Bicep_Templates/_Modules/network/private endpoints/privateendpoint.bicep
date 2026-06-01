///// ---------------------- HEADER ---------------------- /////

// Bicep file for deploying a Private Endpoint for a Storage Account (File Share)
//
// Authors: Michele Blum & Flavio Meyer
// Created: 01.03.2025
// Updated: 29.05.2026
// Notes:
// - This module must be deployed at resource group scope.
// - The subnet (VNet) referenced must exist in the same resource group where this module is deployed.
// - The storage account may live in a different resource group; pass its resource group name using rgName.
// - If you pass a storage account located in another subscription, update the storage account reference accordingly.

///// ---------------------- HEADER END ---------------------- /////

///// ---------------------- CHANGELOG ---------------------- /////

// Version: 1.0.0
// Date: 01.03.2025
// - Initial version
//
// Version: 1.1.0
// Date: 14.05.2026
// - Add parameter docs and defaults
//
// Version: 1.2.0
// Date: 29.05.2026
// - Apply consistent formatting, parameter validation and additional outputs

///// ---------------------- CHANGELOG END ---------------------- /////

///// ---------------------- SCOPE ---------------------- /////

// Module must be deployed at resource group scope
targetScope = 'resourceGroup'

///// ---------------------- SCOPE END ---------------------- /////

///// ---------------------- PARAMETERS ---------------------- /////

// Resource group name that contains the storage account (use the storage RG name).
@description('Resource group containing the storage account.')
@minLength(1)
@maxLength(90)
param rgName string

// Name of the existing virtual network (must be in this module deployment resource group).
@description('Name of the existing virtual network (must be in the same resource group where this module is deployed).')
@minLength(1)
@maxLength(64)
param vnetName string

// Name of the existing subnet (must exist under the provided vnetName).
@description('Name of the existing subnet.')
@minLength(1)
@maxLength(80)
param snetName string

// Name of the existing storage account (may reside in resource group rgName).
@description('Name of the existing storage account.')
@minLength(3)
@maxLength(24)
param saName string

// Name of the private endpoint to create.
@description('Name of the private endpoint to create.')
@minLength(2)
@maxLength(64)
param pepName string

// Location for the private endpoint resource (must match the subnet region).
@description('Location/region of the private endpoint. Must match the subnet region.')
@minLength(1)
@maxLength(64)
param pepLocation string

// Tags applied to the private endpoint (optional).
@description('Tags applied to the private endpoint.')
param pepTags object = {}

// Private endpoint connection name (child connection name).
@description('Name of the private endpoint connection (child resource).')
@minLength(1)
@maxLength(80)
param pepConnectionName string

// Optional custom network interface name for the private endpoint.
@description('Custom network interface name for the private endpoint (optional).')
@minLength(1)
@maxLength(80)
param pepNicName string

// Group ID for the private link service (file/blob/table/queue/dfs). Default is file.
@description('Group ID for the private link service (file/blob/table/queue/dfs).')
@allowed([
  'file'
  'blob'
  'table'
  'queue'
  'dfs'
])
param pepGroupId string = 'file'

// Private link service connection state status. Note: setting to "Approved" requires permissions on the target resource.
@description('Private link service connection state status (Pending, Approved, Rejected). Setting to Approved requires permission on the target resource to approve connections.')
@allowed([
  'Pending'
  'Approved'
  'Rejected'
])
param pepStatus string = 'Approved'

// Actions required on the private link service connection.
@description('Actions required for the private link service connection (typically None).')
@minLength(1)
@maxLength(64)
param pepActionsRequired string = 'None'

///// ---------------------- PARAMETERS END ---------------------- /////

///// ---------------------- RESOURCES ---------------------- /////

// Existing Virtual Network (must exist in the module deployment RG)
resource virtualnetwork_module 'Microsoft.Network/virtualNetworks@2025-05-01' existing = {
  name: vnetName
}

// Existing Subnet under the existing VNet (must exist in the module deployment RG)
resource subnet_module 'Microsoft.Network/virtualNetworks/subnets@2025-05-01' existing = {
  name: snetName
  parent: virtualnetwork_module
}

// Existing Storage Account (may exist in another resource group; rgName controls the scope)
resource storageaccount_module 'Microsoft.Storage/storageAccounts@2025-08-01' existing = {
  name: saName
  scope: resourceGroup(rgName)
}

// Private Endpoint resource to create
resource privateendpoint_module 'Microsoft.Network/privateEndpoints@2025-05-01' = {
  name: pepName
  location: pepLocation
  tags: pepTags

  properties: {
    // Attach to the existing subnet
    subnet: {
      id: subnet_module.id
    }

    // Optionally set a custom NIC name (omit if empty)
    customNetworkInterfaceName: empty(pepNicName) ? null : pepNicName

    privateLinkServiceConnections: [
      {
        name: pepConnectionName
        properties: {
          privateLinkServiceId: storageaccount_module.id

          groupIds: [
            pepGroupId
          ]

          privateLinkServiceConnectionState: {
            status: pepStatus
            actionsRequired: pepActionsRequired
          }
        }
      }
    ]
  }
  dependsOn: [
    subnet_module
  ]
}

///// ---------------------- RESOURCES END ---------------------- /////

///// ---------------------- OUTPUTS ---------------------- /////

// Private Endpoint resource id
output privateEndpointId string = privateendpoint_module.id

// Private Endpoint network interfaces (for retrieving IPs)
output privateEndpointNetworkInterfaces array = privateendpoint_module.properties.networkInterfaces

// Private Endpoint provisioning state
output privateEndpointProvisioningState string = privateendpoint_module.properties.provisioningState

// Storage account id referenced by the private endpoint
output storageAccountId string = storageaccount_module.id

///// ---------------------- OUTPUTS END ---------------------- /////
