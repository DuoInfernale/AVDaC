///// ---------------------- HEADER ---------------------- /////

// Bicep file for deploying a private endpoint to a storage account (file share)
// Author: Michele Blum & Flavio Meyer
// Date: 01.03.2025

///// ---------------------- HEADER END ---------------------- /////


///// ---------------------- PARAMETERS ---------------------- /////

// The name of the private endpoint to which the private DNS zone group will be added.
@description('The name of the private endpoint to which the private DNS zone group will be added.')
param pepName string

// The name of the private DNS zone to be linked to the private endpoint.
@description('The name of the private DNS zone to be linked to the private endpoint.')
param privateDNSName string

// The name of the private DNS zone group.
@description('The name of the private DNS zone group.')
param pepDnsGroupName string

///// ---------------------- PARAMETERS END ---------------------- /////


///// ---------------------- RESOURCES ---------------------- /////

// Define the existing 'private endpoint' resource
resource pep 'Microsoft.Network/privateEndpoints@2024-05-01' existing = {
  name: pepName
}

// Define the existing 'private DNS zone' resource
resource privatedns 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: privateDNSName
}

// Define the 'private DNS zone group' resource
resource pepdnsgroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  name: pepDnsGroupName
  parent: pep
  properties: {
    privateDnsZoneConfigs: [
      {
        name: privatedns.name
        properties: {
          privateDnsZoneId: privatedns.id
        }
      }
    ]
  }
}

///// ---------------------- RESOURCES END ---------------------- /////


///// ---------------------- OUTPUTS ---------------------- /////
/// ---------------------- Outputs End ---------------------- /////


///// ---------------------- END OF BICEP FILE ---------------------- /////
