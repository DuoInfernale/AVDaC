///// ---------------------- HEADER ---------------------- /////

// Bicep file for deploying a Virtual Desktop Host Pool Type: Pooled Desktop
// Author: Michele Blum & Flavio Meyer
// Date: 01.03.2025

///// ---------------------- HEADER END ---------------------- /////


///// ---------------------- PARAMETERS ---------------------- /////

// The name of the Virtual Desktop Host Pool
@description('The name of the Virtual Desktop Host Pool')
param vdpoolName string

// The location where the Virtual Desktop Host Pool will be deployed
@description('The location of the Virtual Desktop Host Pool')
param vdpoolLocation string

// Tags to be applied to the Virtual Desktop Host Pool
@description('Tags to be applied to the Virtual Desktop Host Pool')
param vdpoolTags object

// The type of the host pool (e.g., Pooled, Personal)
@description('The type of the host pool (e.g., Pooled, Personal)')
param vdpoolType string = 'Pooled'

// The type of the load balancer (e.g., BreadthFirst, DepthFirst)
@description('The type of the load balancer (e.g., BreadthFirst, DepthFirst)')
param vdpoolLoadBalancerType string = 'BreadthFirst'

// The type of the application group (e.g., RemoteApp, Desktop)
@description('The type of the application group (e.g., RemoteApp, Desktop)')
param vdpoolAppGroupType string = 'Desktop'

// The base time for calculating the expiration time for the registration token
@description('The base time for calculating the expiration time for the registration token')
param baseTime string = utcNow('u')

// Custom RDP properties for the host pool
@description('Custom RDP properties for the host pool')
param customRdpProperty string = 'drivestoredirect:s:*;audiomode:i:0;videoplaybackmode:i:1;redirectclipboard:i:1;redirectprinters:i:1;devicestoredirect:s:*;enablecredsspsupport:i:1;redirectwebauthn:i:1;use multimon:i:1;enablerdsaadauth:i:0;autoreconnection enabled:i:1;bandwidthautodetect:i:1;networkautodetect:i:1;compression:i:0;audiocapturemode:i:1;encode redirected video capture:i:1;camerastoredirect:s:*;redirectlocation:i:0;keyboardhook:i:0;maximizetocurrentdisplays:i:1;singlemoninwindowedmode:i:1;screen mode id:i:2;smart sizing:i:1;dynamic resolution:i:1;enablerdsaadauth:i:1'

// The maintenance window settings
@description('The maintenance window settings for the host pool update')
param maintenanceDayOfWeek string = 'Friday'
@description('The maintenance hour for the host pool update')
param maintenanceHour int = 20
@description('The time zone for the maintenance window')
param maintenanceWindowTimeZone string = 'W. Europe Standard Time'

// Configuration for the registration token
@description('Registration token operation')
param registrationTokenOperation string = 'Update'

// Token value (can be empty for a new pool)
@description('The registration token (can be empty for a new pool)')
param token string = ''

// Indicates whether the session host should use local time
@description('Indicates whether the session host should use local time')
param useSessionHostLocalTime bool = true

// Type of the agent update
@description('The type of the agent update')
param agentUpdateType string = 'Scheduled'

///// ---------------------- PARAMETERS END ---------------------- /////


///// ---------------------- VARIABLES ---------------------- /////

// Calculate the expiration time for the registration token
var expirationTime = dateTimeAdd(baseTime, 'PT4H')

///// ---------------------- VARIABLES END ---------------------- /////


///// ---------------------- RESOURCES ---------------------- /////

// Define the 'Virtual Desktop Host Pool' resource
resource vdpool 'Microsoft.DesktopVirtualization/hostPools@2024-04-03' = {
  name: vdpoolName
  location: vdpoolLocation
  tags: vdpoolTags
  properties: {
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

// Output the ID of the host pool
output vdpoolId string = vdpool.id

// Output the name of the host pool
output vdpoolName string = vdpool.name

///// ---------------------- OUTPUTS END ---------------------- /////


///// ---------------------- END OF BICEP FILE ---------------------- /////
