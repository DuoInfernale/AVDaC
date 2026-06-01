///// ---------------------- HEADER ---------------------- /////

// Bicep file for deploying a Virtual Desktop Application Group (Type: Desktop)
// Authors: Michele Blum & Flavio Meyer
// Created: 01.03.2025
// Updated: 29.05.2026
// Notes:
// - Application Groups must be deployed under the resource group scope.
// - Provide the full ARM resource ID of the host pool for vdpoolArmPath.

///// ---------------------- HEADER END ---------------------- /////

///// ---------------------- CHANGELOG ---------------------- /////

// Version: 1.0.0
// Date: 01.03.2025
// - Initial version
//
// Version: 2.0.0
// Date: 29.05.2026
// - Apply consistent formatting, parameter validation and outputs
// - Ensure module is resourceGroup scoped and add helpful defaults

///// ---------------------- CHANGELOG END ---------------------- /////

///// ---------------------- SCOPE ---------------------- /////

// Application Groups must be deployed under the 'resourceGroup' scope
targetScope = 'resourceGroup'

///// ---------------------- SCOPE END ---------------------- /////

///// ---------------------- PARAMETERS ---------------------- /////

// The name of the Virtual Desktop Application Group
@description('The name of the Virtual Desktop Application Group.')
@minLength(3)
@maxLength(64)
param vdagName string

// The location where the Virtual Desktop Application Group will be deployed
@description('The location/region where the Virtual Desktop Application Group will be deployed (for example: westeurope).')
@minLength(1)
@maxLength(64)
param vdagLocation string

// Tags to be applied to the Virtual Desktop Application Group
@description('Tags to be applied to the Virtual Desktop Application Group.')
param vdagTags object = {}

// The type of the application group (Desktop or RemoteApp)
@description('The type of the application group (Desktop or RemoteApp).')
@allowed([
  'Desktop'
  'RemoteApp'
])
param vdagApplicationGroupType string

// A description for the Virtual Desktop Application Group (optional)
@description('A description for the Virtual Desktop Application Group.')
param vdagDescription string = ''

// A friendly name for the Virtual Desktop Application Group (optional)
@description('A friendly name for the Virtual Desktop Application Group.')
param vdagFriendlyName string = ''

// The ARM path (full resource ID) of the host pool to which the application group belongs
@description('The full ARM resource ID of the host pool to which the application group belongs (e.g. /subscriptions/.../resourceGroups/.../providers/Microsoft.DesktopVirtualization/hostPools/...).')
@minLength(1)
param vdpoolArmPath string

// Indicates whether the application group should be shown in the feed
@description('Indicates whether the application group should be shown in the feed.')
param vdagShowInFeed bool = true

// The role definition ID for the user (full resource ID). Default: Desktop Virtualization User
@description('The role definition ID for the user (full resource ID). Defaults to Desktop Virtualization User role.')
param roleDefinitionIdUser string = '/providers/Microsoft.Authorization/roleDefinitions/1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63'

// The object ID of the user or group to assign the role to
@description('The object ID (principalId) of the user or group to assign the role to.')
@minLength(1)
param rbacObjectIdUser string

// The principal type for the role assignment
@description('The principal type for the role assignment.')
@allowed([
  'User'
  'Group'
  'ServicePrincipal'
])
param rbacPrincipalType string = 'Group'

///// ---------------------- PARAMETERS END ---------------------- /////

///// ---------------------- RESOURCES ---------------------- /////

// Virtual Desktop Application Group resource
resource vdag_module 'Microsoft.DesktopVirtualization/applicationGroups@2025-10-10' = {
  name: vdagName
  location: vdagLocation
  tags: vdagTags
  properties: {
    applicationGroupType: vdagApplicationGroupType
    description: vdagDescription
    friendlyName: vdagFriendlyName
    hostPoolArmPath: vdpoolArmPath
    showInFeed: vdagShowInFeed
  }
}

// Role assignment for the specified principal on the application group
resource roleAssignment_module 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(vdag_module.id, roleDefinitionIdUser, rbacObjectIdUser)
  scope: vdag_module
  properties: {
    roleDefinitionId: roleDefinitionIdUser
    principalId: rbacObjectIdUser
    principalType: rbacPrincipalType
  }
}

///// ---------------------- RESOURCES END ---------------------- /////

///// ---------------------- OUTPUTS ---------------------- /////

// Application Group resource id
output vdagId string = vdag_module.id

// Application Group name
output vdagNameOutput string = vdag_module.name

// Expose the application group properties for downstream modules or lookups
output vdagProperties object = vdag_module.properties

// Role assignment id
output vdagRoleAssignmentId string = roleAssignment_module.id

///// ---------------------- OUTPUTS END ---------------------- /////
