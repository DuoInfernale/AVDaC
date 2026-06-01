///// ---------------------- HEADER ---------------------- /////

// Bicep file for deploying a Private DNS Zone.
//
// Authors: Michele Blum & Flavio Meyer
// Created: 01.03.2025
// Updated: 29.05.2026
// Notes:
// - Private DNS zones are global resources but are deployed under a resource group scope.
// - Validate dnsZoneName in CI if you need strict DNS label validation (Bicep has no regex param decorator).

///// ---------------------- HEADER END ---------------------- /////

///// ---------------------- CHANGELOG ---------------------- /////

// Version: 1.0.0
// Date: 01.03.2025
// - Initial version
//
// Version: 1.1.0
// Date: 29.05.2026
// - Apply consistent formatting, parameter validation, defaults and outputs

///// ---------------------- CHANGELOG END ---------------------- /////

///// ---------------------- SCOPE ---------------------- /////

// Module is intended to be deployed at resource group scope
targetScope = 'resourceGroup'

///// ---------------------- SCOPE END ---------------------- /////

///// ---------------------- PARAMETERS ---------------------- /////

// Private DNS Zone name (e.g., privatelink.file.core.windows.net)
// Note: DNS zone names can contain multiple labels; validate in CI if required.
@description('The name of the Private DNS Zone (e.g. privatelink.file.core.windows.net).')
@minLength(1)
@maxLength(255)
param dnsZoneName string

// DNS zone location (always global)
@description('The location for the Private DNS Zone. Use "global".')
param dnsZoneLocation string = 'global'

// Tags applied to the Private DNS Zone (optional)
@description('Tags to be applied to the Private DNS Zone.')
param dnsZoneTags object = {}

///// ---------------------- PARAMETERS END ---------------------- /////

///// ---------------------- RESOURCES ---------------------- /////

// Private DNS Zone
resource dnsZone_module 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: dnsZoneName
  location: dnsZoneLocation
  tags: dnsZoneTags
}

///// ---------------------- RESOURCES END ---------------------- /////

///// ---------------------- OUTPUTS ---------------------- /////

// Private DNS Zone Resource ID
output dnsZoneId string = dnsZone_module.id

// Private DNS Zone name
output dnsZoneName string = dnsZone_module.name

// Private DNS Zone properties object
output dnsZoneProperties object = dnsZone_module.properties

///// ---------------------- OUTPUTS END ---------------------- /////
