///// ---------------------- HEADER ---------------------- /////

// Bicep file for deploying a resource group
// Author: Michele Blum & Flavio Meyer
// Date: 01.03.2025

///// ---------------------- HEADER END ---------------------- /////


///// ---------------------- SCOPE ---------------------- /////

// Resource groups must be deployed under the 'subscription' scope
targetScope = 'subscription'

///// ---------------------- SCOPE END ---------------------- /////


///// ---------------------- PARAMETERS ---------------------- /////

// The name of the resource group to be created
@description('The name of the resource group')
param rgName string

// The location where the resource group will be deployed
@description('The location of the resource group')
param rgLocation string

// Tags to be applied to the resource group
@description('Tags to be applied to the resource group')
param rgTags object

///// ---------------------- PARAMETERS END ---------------------- /////


///// ---------------------- RESOURCES ---------------------- /////

// Define the 'resource group' resource
resource resourcegroup 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: rgName
  location: rgLocation
  tags: rgTags
}

///// ---------------------- RESOURCES END ---------------------- /////


///// ---------------------- OUTPUTS ---------------------- /////

// Output the name of the resource group
output rgName string = resourcegroup.name

///// ---------------------- OUTPUTS END ---------------------- /////


///// ---------------------- END OF BICEP FILE ---------------------- /////
