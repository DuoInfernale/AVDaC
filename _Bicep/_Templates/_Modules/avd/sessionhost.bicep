///// ---------------------- HEADER ---------------------- /////

// Bicep file for deploying a Virtual Desktop Session Host
// Author: Michele Blum & Flavio Meyer
// Date: 01.03.2025

///// ---------------------- HEADER END ---------------------- /////


///// ---------------------- PARAMETERS ---------------------- /////

// The name of the Virtual Desktop Host Pool
@description('The name of the Virtual Desktop Host Pool')
param vdpoolName string

// The name of the VM being created
@description('The name of the virtual machine.')
param vmName string

// The location where the session host will be deployed
@description('The location of the session host.')
param vmLocation string

// Tags to be applied to the session host
@description('Tags to be applied to the session host.')
param vmTags object

// The name of the network interface
@description('The name of the network interface.')
param vmNicName string

// The name of the IP configuration for the NIC
@description('The name of the IP configuration for the NIC.')
param vmNicIpConfigurationName string = 'ipconfig1'

// The ID of the subnet for the spoke AVD
@description('The ID of the subnet for the spoke AVD.')
param snetSpokeAVDId string

// The private IP allocation method for the NIC
@description('The private IP allocation method for the NIC.')
param vmNicipConfigurationsPrivateIPAllocationMethod string = 'Dynamic'

// The OS disk creation option
@description('The OS disk creation option.')
param vmOSDiskCreateOption string = 'FromImage'

// Publisher of the session host image
@description('The image publisher for the session host.')
param sessiohostImageReferencePublisher string = 'microsoftwindowsdesktop'

// Offer of the session host image
@description('The image offer for the session host.')
param sessionhostImageReferenceOffer string = 'office-365'

// SKU of the session host image
@description('The image SKU for the session host.')
param sessionhostImageReferenceSku string = 'win11-24h2-avd-m365'

// Version of the session host image
@description('The image version for the session host.')
param sessionhostImageReferenceVersion string = 'latest'

// Whether the network interface properties should be primary
@description('Indicates whether the network interface properties should be primary.')
param sessionhostNetworkInterfacePropertiesPrimary bool = true

// UEFI settings for secure boot
@description('Indicates whether secure boot is enabled.')
param sessionhostSecurityProfileUefiSettingsSecureBootEnabled bool = true

// UEFI settings for vTPM
@description('Indicates whether vTPM is enabled.')
param sessionhostSecurityProfileUefiSettingsVTpmEnabled bool = true

// Security type for the session host
@description('The security type for the session host.')
param sessionhostSecurityProfileSecurityType string = 'TrustedLaunch'

// URL for the artifacts location
@description('The URL of the artifacts location.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/RDS-Templates/master/ARM-wvd-templates/DSC/Configuration.zip'

// The local admin username
@description('The local admin username.')
param vmlocaladminName string

// The local admin password
@secure()
@description('The local admin password.')
param vmlocaladminPassword string

// Type of identity for the session host
@description('The type of identity for the session host.')
param sessionhostIdentityType string = 'SystemAssigned'

// Size of the virtual machine
@description('The size of the virtual machine.')
param vmSize string

// License type for the VM
@description('The license type for the VM.')
param licenseType string = 'Windows_Client'

// Role definition ID for the RBAC role assignment for users
@description('The role definition ID for the RBAC role assignment for users.')
param roleDefintionIdUser string = '/providers/Microsoft.Authorization/roleDefinitions/fb879df8-f326-4884-b1cf-06f3ad86be52' // Virtual Machine User Login

// The object ID of the user for RBAC
@description('The object ID of the user.')
param rbacObjectIdUser string

// The principal type for the RBAC role assignment
@description('The principal type for the RBAC role assignment.')
param rbacPrincipalType string = 'Group'

///// ---------------------- PARAMETERS END ---------------------- /////


///// ---------------------- RESOURCES ---------------------- /////

// Define the existing 'Virtual Desktop Host Pool' resource
resource vdpool 'Microsoft.DesktopVirtualization/hostPools@2024-04-03' existing = {
  name: vdpoolName
}

// Create a network interface for the session host
resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: vmNicName
  location: vmLocation
  tags: vmTags
  properties: {
    ipConfigurations: [
      {
        name: vmNicIpConfigurationName
        properties: {
          subnet: {
            id: snetSpokeAVDId
          }
          privateIPAllocationMethod: vmNicipConfigurationsPrivateIPAllocationMethod
        }
      }
    ]
  }
}

// Create the session host
resource sessionhost 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: vmName
  location: vmLocation
  tags: vmTags
  identity: {
    type: sessionhostIdentityType
  }
  properties: {
    osProfile: {
      computerName: vmName
      adminUsername: vmlocaladminName
      adminPassword: vmlocaladminPassword
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: sessiohostImageReferencePublisher
        offer: sessionhostImageReferenceOffer
        sku: sessionhostImageReferenceSku
        version: sessionhostImageReferenceVersion
      }
      osDisk: {
        createOption: vmOSDiskCreateOption
      }
    }
    licenseType: licenseType
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            primary: sessionhostNetworkInterfacePropertiesPrimary
          }
        }
      ]
    }
    securityProfile: {
      uefiSettings: {
        secureBootEnabled: sessionhostSecurityProfileUefiSettingsSecureBootEnabled
        vTpmEnabled: sessionhostSecurityProfileUefiSettingsVTpmEnabled
      }
      securityType: sessionhostSecurityProfileSecurityType
    }
  }
}

// Domain Join Extension - Contains logic for AADJoin
resource entraidjoin 'Microsoft.Compute/virtualMachines/extensions@2024-07-01' = {
  parent: sessionhost
  name: 'EntraIDLoginForWindows'
  location: vmLocation
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: false
    settings: {
      mdmId: '0000000a-0000-0000-c000-000000000000'
    }
  }
}

// DSC Extension - Contains logic for installing AVD agents
resource avdagentinstallation 'Microsoft.Compute/virtualMachines/extensions@2024-07-01' = {
  parent: sessionhost
  name: 'AddSessionHostToHostPool'
  location: vmLocation
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.83'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: artifactsLocation
      configurationFunction: 'Configuration.ps1\\AddSessionHost'
      properties: {
        hostPoolName: vdpool.name
        aadJoin: true
      }
    }
    protectedSettings: {
      properties: {
        registrationInfoToken: first(vdpool.listRegistrationTokens().value).?token
      }
    }
  }
  dependsOn: [
    entraidjoin
  ]
}

// Set the locale and culture settings for the session host
resource avdSetLocaleAndCulture 'Microsoft.Compute/virtualMachines/runCommands@2024-07-01' = {
  parent: sessionhost
  name: 'SetLocaleAndCulture'
  location: vmLocation
  properties: {
    source: {
      script: '''
      # Define Variables
      $xmlUrl = "https://raw.githubusercontent.com/Quattro99/PowerShellScripts/cb8c8fac5f388ea97cbb056e0002561ac0d1aee5/Azure/AVD/Change%20Language/CHRegion.xml"
      $tempDirPath = "C:\Temp"
      $xmlFilePath = "$tempDirPath\CHRegion.xml"

      if (-not (Test-Path $tempDirPath)) {
          New-Item -Path "C:\" -Name "Temp" -ItemType "Directory"
      }

      if (-not (Test-Path $xmlFilePath)) {
          Invoke-WebRequest -Uri $xmlUrl -OutFile $xmlFilePath
      }

      & "$env:SystemRoot\System32\control.exe" "intl.cpl,,/f:`"$xmlFilePath`""
      tzutil /s "W. Europe Standard Time"
      Set-Culture de-CH
      '''
    }
  }
  dependsOn: [
    avdagentinstallation
  ]
}

// Set the time zone to W. Europe Standard Time
resource avdsettimezone 'Microsoft.Compute/virtualMachines/runCommands@2024-07-01' = {
  parent: sessionhost
  name: 'MicrosoftPowerShellSetTimeZone'
  location: vmLocation
  properties: {
    source: {
      script: 'Set-TimeZone -Id "W. Europe Standard Time"'
    }
  }
  dependsOn: [
    avdSetLocaleAndCulture
  ]
}

// Assign RBAC permissions to the session hosts
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(sessionhost.id, roleDefintionIdUser, rbacObjectIdUser)
  scope: sessionhost
  properties: {
    roleDefinitionId: roleDefintionIdUser
    principalId: rbacObjectIdUser
    principalType: rbacPrincipalType
  }
}

///// ---------------------- RESOURCES END ---------------------- /////


///// ---------------------- OUTPUTS ---------------------- /////
/// ---------------------- OUTPUTS END ---------------------- /////


///// ---------------------- END OF BICEP FILE ---------------------- /////
