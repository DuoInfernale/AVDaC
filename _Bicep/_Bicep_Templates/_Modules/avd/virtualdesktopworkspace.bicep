///// ---------------------- HEADER ---------------------- /////

// Bicep file for deploying a Virtual Desktop Workspace
// Authors: Michele Blum & Flavio Meyer
// Created: 01.03.2025
// Updated: 29.05.2026
// Notes:
// - This module deploys an AVD Workspace and references existing Application Groups.
// - Deploy this module at resource group scope or call with scope: resourceGroup('<rgName>').

///// ---------------------- HEADER END ---------------------- /////

///// ---------------------- CHANGELOG ---------------------- /////

// Version: 1.0.0
// Date: 01.03.2025
// - Initial version
//
// Version: 1.1.0
// Date: 27.05.2026
// - Apply consistent formatting, parameter validation and outputs
//
// Version: 1.2.0
// Date: 29.05.2026
// - Added resource group param and safe defaults

///// ---------------------- CHANGELOG END ---------------------- /////

///// ---------------------- SCOPE ---------------------- /////

// Module is intended to be deployed at resource group scope
targetScope = 'resourceGroup'

///// ---------------------- SCOPE END ---------------------- /////

///// ---------------------- PARAMETERS ---------------------- /////

// The name of the Virtual Desktop Workspace
@description('The name of the Virtual Desktop Workspace.')
@minLength(3)
@maxLength(64)
param vdwsName string

// The location where the Virtual Desktop Workspace will be deployed
@description('The location/region of the Virtual Desktop Workspace (for example: westeurope).')
@minLength(1)
@maxLength(64)
param vdwsLocation string

// Tags to be applied to the Virtual Desktop Workspace (optional)
@description('Tags to be applied to the Virtual Desktop Workspace.')
param vdwsTags object = {}

// The ARM paths of the application groups to which the workspace belongs
// Accepts an array of full ARM IDs (e.g. /subscriptions/.../resourceGroups/.../providers/Microsoft.DesktopVirtualization/applicationGroups/...)
@description('Array of ARM resource IDs for Application Groups to reference from the Workspace.')
param vdagReferences array = []

// A description for the Virtual Desktop Workspace (optional)
@description('A description for the Virtual Desktop Workspace.')
param vdwsDescription string = ''

// A friendly name for the Virtual Desktop Workspace (optional)
@description('A friendly name for the Virtual Desktop Workspace.')
param vdwsFriendlyName string = ''

// Indicates whether the workspace should be accessible from the public network
@description('Indicates whether the workspace should be accessible from the public network.')
@allowed([
  'Enabled'
  'Disabled'
])
param vdwsPublicNetworkAccess string = 'Enabled'

///// ---------------------- PARAMETERS END ---------------------- /////

///// ---------------------- RESOURCES ---------------------- /////

// Virtual Desktop Workspace resource
resource avdWorkspace_module 'Microsoft.DesktopVirtualization/workspaces@2025-10-10' = {
  name: vdwsName
  location: vdwsLocation
  tags: vdwsTags
  properties: {
    applicationGroupReferences: vdagReferences
    description: vdwsDescription
    friendlyName: vdwsFriendlyName
    publicNetworkAccess: vdwsPublicNetworkAccess
  }
}

///// ---------------------- RESOURCES END ---------------------- /////

///// ---------------------- OUTPUTS ---------------------- /////

// Workspace resource id
output workspaceId string = avdWorkspace_module.id

// Workspace name
output workspaceName string = avdWorkspace_module.name

// Expose the workspace properties object for downstream modules or lookups
output workspaceProperties object = avdWorkspace_module.properties

// Application group references (as configured on the deployed Workspace)
output workspaceApplicationGroupReferences array = avdWorkspace_module.properties.applicationGroupReferences

///// ---------------------- OUTPUTS END ---------------------- /////
