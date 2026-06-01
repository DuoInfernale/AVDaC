///// ---------------------- HEADER ---------------------- /////

// Bicep file for creating a Private DNS Zone Group for an existing Private Endpoint.
//
// Authors: Michele Blum & Flavio Meyer
// Created: 01.03.2025
// Updated: 29.05.2026
// Notes:
// - This module must be deployed at resource group scope (private endpoints are RG scoped).
// - dnsZoneName accepts either a zone name (e.g. privatelink.file.core.windows.net) or a full resource id.
//   If you pass a full resource id for a zone in a different resource group/subscription you must also
//   deploy this module into that same scope or extend the module to accept and apply the resourceId scope.

///// ---------------------- HEADER END ---------------------- /////

///// ---------------------- CHANGELOG ---------------------- /////

// Version: 1.0.0
// Date: 01.03.2025
// - Initial version
//
// Version: 1.1.0
// Date: 29.05.2026
// - Apply consistent formatting, parameter validation and outputs
// - Accept full resource id or zone name for dnsZoneName (name segment extracted)

///// ---------------------- CHANGELOG END ---------------------- /////

///// ---------------------- SCOPE ---------------------- /////

// Module must be deployed at resource group scope
targetScope = 'resourceGroup'

///// ---------------------- SCOPE END ---------------------- /////

///// ---------------------- PARAMETERS ---------------------- /////

// Name of the existing private endpoint in this resource group
@description('The name of the existing Private Endpoint (resource group scope).')
@minLength(2)
@maxLength(64)
param pepName string

// Name of the private DNS zone to link (or the full resource id of the zone).
// Examples: 'privatelink.file.core.windows.net' OR '/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net'
@description('The private DNS zone name (or full resource id) to link to the Private Endpoint.')
@minLength(1)
@maxLength(1024)
param dnsZoneName string

// Name of the private DNS zone group (child resource name under the private endpoint)
@description('Name of the Private DNS Zone Group to create under the Private Endpoint.')
@minLength(1)
@maxLength(64)
param dnsZoneGroupName string

///// ---------------------- PARAMETERS END ---------------------- /////

///// ---------------------- VARIABLES ---------------------- /////

// If the caller passed a full resource id, extract the last segment (the zone name).
// Note: extracting the name does not change resource scope; cross-RG zones still require appropriate deployment scope.
var dnsZoneNameOnly = contains(dnsZoneName, '/providers/') ? last(split(dnsZoneName, '/')) : dnsZoneName

///// ---------------------- VARIABLES END ---------------------- /////

///// ---------------------- RESOURCES ---------------------- /////

// Existing Private Endpoint (must exist in the same resource group / deployment scope)
resource privateendpoint_module 'Microsoft.Network/privateEndpoints@2025-05-01' existing = {
  name: pepName
}

// Existing Private DNS Zone (must exist). If the zone lives in another resource group/subscription,
// the deployment scope must match that resource group/subscription; otherwise reference with proper scope.
resource privatednszone_module 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: dnsZoneNameOnly
}

// Private DNS Zone Group under the Private Endpoint linking the DNS zone for privatelink resolution
resource privatednszonegroup_module 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2025-05-01' = {
  name: dnsZoneGroupName
  parent: privateendpoint_module
  properties: {
    privateDnsZoneConfigs: [
      {
        name: privatednszone_module.name
        properties: {
          privateDnsZoneId: privatednszone_module.id
        }
      }
    ]
  }
  dependsOn: [
    privateendpoint_module
    privatednszone_module
  ]
}

///// ---------------------- RESOURCES END ---------------------- /////

///// ---------------------- OUTPUTS ---------------------- /////

// Created Private DNS Zone Group id
output privateDnsZoneGroupId string = privatednszonegroup_module.id

// Created Private DNS Zone Group name
output privateDnsZoneGroupName string = privatednszonegroup_module.name

// Parent Private Endpoint id
output privateEndpointId string = privateendpoint_module.id

// Linked Private DNS Zone id
output privateDnsZoneId string = privatednszone_module.id

///// ---------------------- OUTPUTS END ---------------------- /////
