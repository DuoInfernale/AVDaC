///// ---------------------- HEADER ---------------------- /////

// Bicep file for deploying a Virtual Desktop Host Pool (Type: Pooled Desktop)
// Authors: Michele Blum & Flavio Meyer
// Created: 01.03.2025
// Updated: 29.05.2026
// Notes:
// - This module deploys an AVD host pool (hostPools resource).
// - Deploy at resource group scope or call with scope: resourceGroup('<rgName>').

///// ---------------------- HEADER END ---------------------- /////

///// ---------------------- CHANGELOG ---------------------- /////

// Version: 1.0.0
// Date: 01.03.2025
// - Initial version
//
// Version: 2.0.0
// Date: 29.05.2026
// - Apply consistent formatting, parameter validation, scope param and useful outputs

///// ---------------------- CHANGELOG END ---------------------- /////

///// ---------------------- SCOPE ---------------------- /////

// This module is intended to be deployed at resource group scope
targetScope = 'resourceGroup'

///// ---------------------- SCOPE END ---------------------- /////

///// ---------------------- PARAMETERS ---------------------- /////

// The name of the Virtual Desktop Host Pool
@description('The name of the Virtual Desktop Host Pool.')
@minLength(3)
@maxLength(64)
param vdpoolName string

// The location where the Virtual Desktop Host Pool will be deployed
@description('The location/region where the host pool will be deployed (for example: westeurope).')
@minLength(1)
@maxLength(64)
param vdpoolLocation string

// Tags to be applied to the Virtual Desktop Host Pool
@description('Tags to be applied to the Virtual Desktop Host Pool.')
param vdpoolTags object = {}

// The type of the host pool (Pooled or Personal)
@description('The type of the host pool (Pooled or Personal).')
@allowed([
  'Pooled'
  'Personal'
])
param vdpoolType string = 'Pooled'

// The type of the load balancer (BreadthFirst or DepthFirst)
@description('The load balancing algorithm to use.')
@allowed([
  'BreadthFirst'
  'DepthFirst'
])
param vdpoolLoadBalancerType string = 'BreadthFirst'

// The preferred application group type for the host pool (Desktop or RemoteApp)
@description('The preferred application group type for the host pool.')
@allowed([
  'Desktop'
  'RemoteApp'
])
param vdpoolAppGroupType string = 'Desktop'

// Base time used to calculate registration token expiration (ISO 8601). Defaults to now.
@description('Base time used for calculating the expiration time for the registration token (ISO 8601).')
param baseTime string = utcNow('u')

// Custom RDP properties for the host pool (string passed to API)
@description('Custom RDP properties for the host pool.')
param customRdpProperty string = 'drivestoredirect:s:*;audiomode:i:0;videoplaybackmode:i:1;redirectclipboard:i:1;redirectprinters:i:1;devicestoredirect:s:*;enablecredsspsupport:i:1;redirectwebauthn:i:1;use multimon:i:1;autoreconnection enabled:i:1;bandwidthautodetect:i:1;networkautodetect:i:1;compression:i:0;audiocapturemode:i:1;encode redirected video capture:i:1;camerastoredirect:s:*;redirectlocation:i:0;keyboardhook:i:0;maximizetocurrentdisplays:i:1;singlemoninwindowedmode:i:1;screen mode id:i:2;smart sizing:i:1;dynamic resolution:i:1;enablerdsaadauth:i:1'

// Maintenance window settings
@description('The maintenance day of week for the host pool update.')
@allowed([
  'Monday'
  'Tuesday'
  'Wednesday'
  'Thursday'
  'Friday'
  'Saturday'
  'Sunday'
])
param maintenanceDayOfWeek string = 'Friday'

@description('The maintenance hour for the host pool update (0-23).')
@minValue(0)
@maxValue(23)
param maintenanceHour int = 20

@description('The time zone for the maintenance window.')
param maintenanceWindowTimeZone string = 'W. Europe Standard Time'

// Registration token operation
@description('Registration token operation (Update or None).')
@allowed([
  'Update'
  'None'
])
param registrationTokenOperation string = 'Update'

// Registration token value (secure). Can be empty for a new pool.
@secure()
@description('The registration token (can be empty for a new pool).')
param token string = ''

// Indicates whether the session host should use local time
@description('Indicates whether the session host should use local time.')
param useSessionHostLocalTime bool = true

// Type of agent update
@description('Type of the agent update (Scheduled or Immediate).')
@allowed([
  'Scheduled'
  'Immediate'
])
param agentUpdateType string = 'Scheduled'

///// ---------------------- PARAMETERS END ---------------------- /////

///// ---------------------- VARIABLES ---------------------- /////

// Calculate the expiration time for the registration token (4 hours from baseTime)
var expirationTime = dateTimeAdd(baseTime, 'PT4H')

///// ---------------------- VARIABLES END ---------------------- /////

///// ---------------------- RESOURCES ---------------------- /////

// Virtual Desktop Host Pool resource
resource vdpool_module 'Microsoft.DesktopVirtualization/hostPools@2025-10-10' = {
  name: vdpoolName
  location: vdpoolLocation
  tags: vdpoolTags
  properties: {
    friendlyName: vdpoolName
    hostPoolType: vdpoolType
    loadBalancerType: vdpoolLoadBalancerType
    preferredAppGroupType: vdpoolAppGroupType
    customRdpProperty: customRdpProperty
    registrationInfo: {
      expirationTime: expirationTime
      registrationTokenOperation: registrationTokenOperation
      token: token
    }
    agentUpdate: {
      maintenanceWindows: [
        {
          dayOfWeek: maintenanceDayOfWeek
          hour: maintenanceHour
        }
      ]
      maintenanceWindowTimeZone: maintenanceWindowTimeZone
      type: agentUpdateType
      useSessionHostLocalTime: useSessionHostLocalTime
    }
  }
}

///// ---------------------- RESOURCES END ---------------------- /////

///// ---------------------- OUTPUTS ---------------------- /////

// Host Pool resource id
output vdpoolId string = vdpool_module.id

// Host Pool resource name
output vdpoolName string = vdpool_module.name

// Expose the host pool properties for downstream modules or lookups
output vdpoolProperties object = vdpool_module.properties

// Agent update / maintenance configuration
output vdpoolAgentUpdate object = vdpool_module.properties.agentUpdate

///// ---------------------- OUTPUTS END ---------------------- /////
