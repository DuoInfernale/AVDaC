///// ---------------------- HEADER ---------------------- /////

// Bicep file for creating a Private DNS Zone Group for an existing Private Endpoint
// This module links an existing Private DNS Zone to an existing Private Endpoint
//
// Authors: Michele Blum & Flavio Meyer
// Created: 01.03.2025
// Updated: 29.05.2026
// Notes:
// - This module must be deployed at resource group scope (private endpoints are RG scoped).
// - The private DNS zone must exist prior to deploying this module (or be created in the same deployment scope).
// - If the private DNS zone lives in a different resource group, pass the full resource id (and update the existing resource scope accordingly).

///// ---------------------- HEADER END ---------------------- /////

///// ---------------------- CHANGELOG ---------------------- /////

// Version: 1.0.0
// Date: 01.03.2025
// - Initial version
//
// Version: 1.1.0
// Date: 29.05.2026
// - Added parameter validation and outputs
// - Updated documentation and descriptions
// - Refactored resource declarations for clarity
// - Updated to latest API versions

///// ---------------------- CHANGELOG END ---------------------- /////

///// ---------------------- SCOPE ---------------------- /////

// Module must be deployed at resource group scope
targetScope = 'resourceGroup'

///// ---------------------- SCOPE END ---------------------- /////

///// ---------------------- PARAMETERS ---------------------- /////

// Name of the existing Private Endpoint resource (required).
@description('Name of the existing Private Endpoint resource (in the same resource group).')
@minLength(2)
@maxLength(64)
param pepName string

// Name of the existing Private DNS Zone to link (e.g. privatelink.file.core.windows.net).
// If the zone is in another resource group, pass the full resource id instead and adjust the module to reference by id.
@description('Name (or full resource id) of the existing Private DNS Zone to link. If the zone is in a different resource group, pass the full resource id and adjust scopes accordingly.')
@minLength(1)
@maxLength(1024)
param privateDNSName string

// Name to use for the Private DNS Zone Group (child resource of the Private Endpoint).
@description('Name of the Private DNS Zone Group that will be created under the Private Endpoint.')
@minLength(1)
@maxLength(64)
param pepDnsGroupName string

///// ---------------------- PARAMETERS END ---------------------- /////

///// ---------------------- RESOURCES ---------------------- /////

// Existing Private Endpoint (must exist in this resource group / deployment scope)
resource pep_module 'Microsoft.Network/privateEndpoints@2025-05-01' existing = {
  name: pepName
}

// Existing Private DNS Zone (must exist). If you supply a full resource id instead of name,
resource privatedns_module 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: privateDNSName
}

// Private DNS Zone Group under the Private Endpoint linking the DNS zone for privatelink resolution
resource pepdnsgroups_module 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2025-05-01' = {
  name: pepDnsGroupName
  parent: pep_module
  properties: {
    privateDnsZoneConfigs: [
      {
        // friendly name for the config; using the zone name keeps it obvious
        name: privatedns_module.name
        properties: {
          privateDnsZoneId: privatedns_module.id
        }
      }
    ]
  }
}

///// ---------------------- RESOURCES END ---------------------- /////

///// ---------------------- OUTPUTS ---------------------- /////

// The id of the created Private DNS Zone Group
output privateDnsZoneGroupId string = pepdnsgroups_module.id

// The name of the created Private DNS Zone Group
output privateDnsZoneGroupName string = pepdnsgroups_module.name

// The parent Private Endpoint id
output privateEndpointId string = pep_module.id

// The linked Private DNS Zone id
output privateDnsZoneId string = privatedns_module.id

///// ---------------------- OUTPUTS END ---------------------- /////
