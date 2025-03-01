///// ---------------------- HEADER ---------------------- /////

// Bicep file for deploying a private DNS zone
// Author: Michele Blum & Flavio Meyer
// Date: 01.03.2025

///// ---------------------- HEADER END ---------------------- /////


///// ---------------------- PARAMETERS ---------------------- /////

// The name of the private DNS zone to be created.
@description('The name of the private DNS zone.')
param privateDNSName string

// The Azure region where the private DNS zone will be created.
// The value must be global.
@description('The location of the private DNS zone.')
param privateDNSLocation string = 'global'

// Tags to be applied to the private DNS zone for resource management and organization.
@description('Tags to be applied to the private DNS zone.')
param privateDNSTags object

///// ---------------------- PARAMETERS END ---------------------- /////


///// ---------------------- RESOURCES ---------------------- /////

// Define the 'private DNS zone' resource
resource privatedns 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: privateDNSName
  location: privateDNSLocation
  tags: privateDNSTags
}

///// ---------------------- RESOURCES END ---------------------- /////


///// ---------------------- OUTPUTS ---------------------- /////

// Output the name of the private DNS zone
output privateDNSName string = privatedns.name

// Output the ID of the private DNS zone
output privateDNSId string = privatedns.id

///// ---------------------- OUTPUTS END ---------------------- /////


///// ---------------------- END OF BICEP FILE ---------------------- /////
