///// ---------------------- HEADER ---------------------- /////

// Bicep file for deploying a Virtual Desktop Workspace
// Author: Michele Blum & Flavio Meyer
// Date: 01.03.2025

///// ---------------------- HEADER END ---------------------- /////


///// ---------------------- PARAMETERS ---------------------- /////

// The name of the Virtual Desktop Workspace
@description('The name of the Virtual Desktop Workspace')
param vdwsName string

// The location where the Virtual Desktop Workspace will be deployed
@description('The location of the Virtual Desktop Workspace')
param vdwsLocation string

// Tags to be applied to the Virtual Desktop Workspace
@description('Tags to be applied to the Virtual Desktop Workspace')
param vdwsTags object

// The ARM path of the application group to which the workspace belongs
@description('The ARM path of the application group to which the workspace belongs')
param vdagReferences string

// A description for the Virtual Desktop Workspace
@description('A description for the Virtual Desktop Workspace')
param vdwsDescription string

// A friendly name for the Virtual Desktop Workspace
@description('A friendly name for the Virtual Desktop Workspace')
param vdwsFriendlyName string

// Indicates whether the workspace should be accessible from the public network
@description('Indicates whether the workspace should be accessible from the public network')
param vdwsPublicNetworkAccess string = 'Enabled'

///// ---------------------- PARAMETERS END ---------------------- /////


///// ---------------------- RESOURCES ---------------------- /////

// Define the 'Virtual Desktop Workspace' resource
resource avdWorkspace 'Microsoft.DesktopVirtualization/workspaces@2024-04-03' = {
  name: vdwsName
  location: vdwsLocation
  tags: vdwsTags
  properties: {
    applicationGroupReferences: [
      vdagReferences
    ]
    description: vdwsDescription
    friendlyName: vdwsFriendlyName
    publicNetworkAccess: vdwsPublicNetworkAccess
  }
}

///// ---------------------- RESOURCES END ---------------------- /////


///// ---------------------- OUTPUTS ---------------------- /////
/// ---------------------- OUTPUTS END ---------------------- /////


///// ---------------------- END OF BICEP FILE ---------------------- /////
