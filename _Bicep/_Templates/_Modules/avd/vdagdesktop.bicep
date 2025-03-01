///// ---------------------- HEADER ---------------------- /////

// Bicep file for deploying a Virtual Desktop Application Group Type: Desktop
// Author: Michele Blum & Flavio Meyer
// Date: 01.03.2025

///// ---------------------- HEADER END ---------------------- /////


///// ---------------------- PARAMETERS ---------------------- /////

// Application Groups must be deployed under the 'resource group' scope
targetScope = 'resourceGroup'

// The name of the Virtual Desktop Application Group
@description('The name of the Virtual Desktop Application Group')
param vdagName string

// The location where the Virtual Desktop Application Group will be deployed
@description('The location of the Virtual Desktop Application Group')
param vdagLocation string

// Tags to be applied to the Virtual Desktop Application Group
@description('Tags to be applied to the Virtual Desktop Application Group')
param vdagTags object

// The type of the application group (e.g., RemoteApp, Desktop)
@description('The type of the application group (e.g., RemoteApp, Desktop)')
param vdagApplicationGroupType string = 'Desktop'

// A description for the Virtual Desktop Application Group
@description('A description for the Virtual Desktop Application Group')
param vdagDescription string

// A friendly name for the Virtual Desktop Application Group
@description('A friendly name for the Virtual Desktop Application Group')
param vdagFriendlyName string

// The ARM path of the host pool to which the application group belongs
@description('The ARM path of the host pool to which the application group belongs')
param vdpoolId string

// Indicates whether the application group should be shown in the feed
@description('Indicates whether the application group should be shown in the feed')
param vdagShowInFeed bool = true

// The role definition ID for the user role
@description('The role definition ID for the user role')
param roleDefintionIdUser string = '/providers/Microsoft.Authorization/roleDefinitions/1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63' // Desktop Virtualization User

// The object ID of the user
@description('The object ID of the user')
param rbacObjectIdUser string

// The principal type for the user
@description('The principal type for the user')
param rbacPrincipalType string = 'Group'

///// ---------------------- PARAMETERS END ---------------------- /////


///// ---------------------- RESOURCES ---------------------- /////

// Define the 'Virtual Desktop Application Group' resource
resource vdag 'Microsoft.DesktopVirtualization/applicationGroups@2024-04-03' = {
  name: vdagName
  location: vdagLocation
  tags: vdagTags
  properties: {
    applicationGroupType: vdagApplicationGroupType
    description: vdagDescription
    friendlyName: vdagFriendlyName
    hostPoolArmPath: vdpoolId
    showInFeed: vdagShowInFeed
  }
}

// Define the role assignment for the user
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(vdag.id, roleDefintionIdUser, rbacObjectIdUser)
  scope: vdag
  properties: {
    roleDefinitionId: roleDefintionIdUser
    principalId: rbacObjectIdUser
    principalType: rbacPrincipalType
  }
}

///// ---------------------- RESOURCES END ---------------------- /////


///// ---------------------- OUTPUTS ---------------------- /////

// Output the ID of the Virtual Desktop Application Group
output vdagId string = vdag.id

///// ---------------------- OUTPUTS END ---------------------- /////


///// ---------------------- END OF BICEP FILE ---------------------- /////
