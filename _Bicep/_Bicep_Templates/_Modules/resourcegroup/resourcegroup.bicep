///// ---------------------- HEADER ---------------------- /////

// Bicep file for deploying a resource group
// Authors: Michele Blum & Flavio Meyer
// Created: 07.05.2026
// Updated: 29.05.2026
// Notes:
// - This module must be deployed at the subscription scope (resource groups are subscription-scoped).
// - Provide a valid Azure region for rgLocation.

///// ---------------------- HEADER END ---------------------- /////

///// ---------------------- CHANGELOG ---------------------- /////

// Version: 1.0.0
// Date: 07.05.2026
// - Initial version
//
// Version: 1.1.0
// Date: 29.05.2026
// - Apply consistent formatting, parameter validation and defaults

///// ---------------------- CHANGELOG END ---------------------- /////

///// ---------------------- SCOPE ---------------------- /////

// Resource groups must be deployed under the 'subscription' scope
targetScope = 'subscription'

///// ---------------------- SCOPE END ---------------------- /////

///// ---------------------- PARAMETERS ---------------------- /////

// The name of the resource group to be created.
@description('The name of the resource group to create.')
@minLength(1)
@maxLength(90)
param rgName string

// The location where the resource group will be deployed (Azure region).
@description('The Azure region where the resource group will be created (for example: westeurope).')
@minLength(1)
@maxLength(64)
param rgLocation string

// Tags to be applied to the resource group. Optional.
@description('Tags to be applied to the resource group.')
param rgTags object = {}

///// ---------------------- PARAMETERS END ---------------------- /////

///// ---------------------- RESOURCES ---------------------- /////

// Resource group
resource resourcegroup_module 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: rgName
  location: rgLocation
  tags: rgTags
}

///// ---------------------- RESOURCES END ---------------------- /////

///// ---------------------- OUTPUTS ---------------------- /////

// Output the ID of the resource group
output resourceGroupId string = resourcegroup_module.id

// Output the name of the resource group
output resourceGroupName string = resourcegroup_module.name

// Output the location of the resource group
output resourceGroupLocation string = resourcegroup_module.location

///// ---------------------- OUTPUTS END ---------------------- /////
