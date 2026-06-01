///// ---------------------- HEADER ---------------------- /////

// Bicep file for deploying a Virtual Desktop Session Host (VM + NIC + extensions + RBAC)
//
// Authors: Michele Blum & Flavio Meyer
// Created: 01.03.2025
// Updated: 29.05.2026
// Notes:
// - This module deploys a VM intended as an AVD session host, its NIC, required VM extensions
//   (Entra/AAD login, DSC to install/register AVD agent, RunCommand runbooks) and RBAC role assignment.
// - Deploy this module at resource group scope (default). To target a different RG, call this module
//   with scope: resourceGroup('<rgName>').

///// ---------------------- HEADER END ---------------------- /////

///// ---------------------- CHANGELOG ---------------------- /////

// Version: 1.0.0
// Date: 01.03.2025
// - Initial version
//
// Version: 1.1.0
// Date: 27.05.2026
// - Apply consistent formatting and parameter validation
//
// Version: 1.2.0
// Date: 29.05.2026
// - Update API versions, optional tags/defaults, improved outputs

///// ---------------------- CHANGELOG END ---------------------- /////

///// ---------------------- SCOPE ---------------------- /////

// Module is intended to be deployed at resource group scope
targetScope = 'resourceGroup'

///// ---------------------- SCOPE END ---------------------- /////

///// ---------------------- PARAMETERS ---------------------- /////

@description('The name of the existing Virtual Desktop Host Pool.')
@minLength(3)
@maxLength(64)
param vdpoolName string

@description('The name of the virtual machine (also used as computerName). For Windows, follow hostname rules (1-15).')
@minLength(1)
@maxLength(15)
param vmName string

@description('Azure region where the session host will be deployed (e.g. westeurope).')
@minLength(1)
@maxLength(64)
param vmLocation string

@description('Tags to apply to VM, NIC and extensions.')
param vmTags object = {}

@description('The name of the network interface to create for the VM.')
@minLength(1)
@maxLength(80)
param vmNicName string

@description('The name of the IP configuration for the NIC.')
param vmNicIpConfigurationName string = 'ipconfig1'

@description('Resource ID of the subnet to attach the NIC to.')
@minLength(1)
param snetSpokeAVDId string

@description('The private IP allocation method for the NIC (Dynamic or Static).')
@allowed([
  'Dynamic'
  'Static'
])
param vmNicipConfigurationsPrivateIPAllocationMethod string = 'Dynamic'

@description('The OS disk create option (FromImage, Attach, etc.).')
param vmOSDiskCreateOption string = 'FromImage'

@description('Image publisher for the session host.')
param sessionhostImageReferencePublisher string = 'microsoftwindowsdesktop'

@description('Image offer for the session host.')
param sessionhostImageReferenceOffer string = 'windows-11'

@description('Image SKU for the session host.')
param sessionhostImageReferenceSku string = 'win11-25h2-avd'

@description('Image version for the session host.')
param sessionhostImageReferenceVersion string = 'latest'

@description('Whether the network interface should be marked as primary on the VM.')
param sessionhostNetworkInterfacePropertiesPrimary bool = true

@description('Secure Boot enabled for UEFI settings.')
param sessionhostSecurityProfileUefiSettingsSecureBootEnabled bool = true

@description('vTPM enabled for UEFI settings.')
param sessionhostSecurityProfileUefiSettingsVTpmEnabled bool = true

@description('Security type for the session host (e.g., TrustedLaunch).')
param sessionhostSecurityProfileSecurityType string = 'TrustedLaunch'

@description('Enable encryption at host for all VM disks, including the temporary/resource disk.')
param sessionhostSecurityProfileEncryptionAtHost bool = true

@description('URL of the artifacts zip containing DSC configuration (used by DSC extension).')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/RDS-Templates/master/ARM-wvd-templates/DSC/Configuration.zip'

@description('Local admin username for the VM.')
@minLength(1)
param vmlocaladminName string

@secure()
@description('Local admin password for the VM.')
param vmlocaladminPassword string

@description('Managed identity type for the VM.')
@allowed([
  'SystemAssigned'
  'UserAssigned'
  'None'
])
param sessionhostIdentityType string = 'SystemAssigned'

@description('VM size for the session host (e.g. Standard_D2as_v5).')
@minLength(1)
param vmSize string

@description('License type for the VM (e.g., Windows_Client, Windows_Server).')
param licenseType string = 'Windows_Client'

@description('Role definition id for VM login RBAC (full resource id). Default: Virtual Machine User Login.')
param roleDefintionIdUser string = '/providers/Microsoft.Authorization/roleDefinitions/fb879df8-f326-4884-b1cf-06f3ad86be52'

@description('Object ID (principal) to grant VM login RBAC to (user/group/service principal).')
@minLength(1)
param rbacObjectIdUser string

@description('Principal type for the RBAC assignment (User, Group, ServicePrincipal).')
@allowed([
  'User'
  'Group'
  'ServicePrincipal'
])
param rbacPrincipalType string = 'Group'

///// ---------------------- PARAMETERS END ---------------------- /////

///// ---------------------- RESOURCES ---------------------- /////

// Existing Virtual Desktop Host Pool (reference)
resource vdpool_module 'Microsoft.DesktopVirtualization/hostPools@2025-10-10' existing = {
  name: vdpoolName
}

// Network Interface for the session host
resource nic_module 'Microsoft.Network/networkInterfaces@2025-05-01' = {
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

// Virtual Machine (Session Host)
resource sessionhost_module 'Microsoft.Compute/virtualMachines@2025-11-01' = {
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
        publisher: sessionhostImageReferencePublisher
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
          id: nic_module.id
          properties: {
            primary: sessionhostNetworkInterfacePropertiesPrimary
          }
        }
      ]
    }
    securityProfile: {
      encryptionAtHost: sessionhostSecurityProfileEncryptionAtHost
      uefiSettings: {
        secureBootEnabled: sessionhostSecurityProfileUefiSettingsSecureBootEnabled
        vTpmEnabled: sessionhostSecurityProfileUefiSettingsVTpmEnabled
      }
      securityType: sessionhostSecurityProfileSecurityType
    }
  }
}

// Domain Join / Entra ID extension (AADLoginForWindows)
resource entraidjoin_module 'Microsoft.Compute/virtualMachines/extensions@2025-11-01' = {
  parent: sessionhost_module
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

// DSC Extension - Add session host to host pool (install AVD agent & register)
resource avdagentinstallation_module 'Microsoft.Compute/virtualMachines/extensions@2025-11-01' = {
  parent: sessionhost_module
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
        hostPoolName: vdpool_module.name
        aadJoin: true
      }
    }
    protectedSettings: {
      properties: {
        registrationInfoToken: first(vdpool_module.listRegistrationTokens().value).?token
      }
    }
  }
  dependsOn: [
    entraidjoin_module
  ]
}

// RunCommand to set locale and culture
resource avdSetLocaleAndCulture_module 'Microsoft.Compute/virtualMachines/runCommands@2025-11-01' = {
  parent: sessionhost_module
  name: 'SetLocaleAndCulture'
  location: vmLocation
  properties: {
    source: {
      script: '''
      # Define Variables
      $xmlUrl = "https://github.com/Quattro99/PowerShellScripts/blob/6e2ec141fe5de990499b22689fc2322c25b2b1bb/Azure/AVD/Change%20Language/CHRegion.xml"
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
    avdagentinstallation_module
  ]
}

// RunCommand to set time zone
resource avdsettimezone_module 'Microsoft.Compute/virtualMachines/runCommands@2025-11-01' = {
  parent: sessionhost_module
  name: 'MicrosoftPowerShellSetTimeZone'
  location: vmLocation
  properties: {
    source: {
      script: 'Set-TimeZone -Id "W. Europe Standard Time"'
    }
  }
  dependsOn: [
    avdSetLocaleAndCulture_module
  ]
}

// Role assignment granting VM login permissions to the specified principal
resource roleAssignment_module 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(sessionhost_module.id, roleDefintionIdUser, rbacObjectIdUser)
  scope: sessionhost_module
  properties: {
    roleDefinitionId: roleDefintionIdUser
    principalId: rbacObjectIdUser
    principalType: rbacPrincipalType
  }
}

///// ---------------------- RESOURCES END ---------------------- /////

///// ---------------------- OUTPUTS ---------------------- /////

// Virtual machine resource id
output vmId string = sessionhost_module.id

// Virtual machine name
output vmNameOutput string = sessionhost_module.name

// Network interface id
output nicId string = nic_module.id

// Role assignment id
output roleAssignmentId string = roleAssignment_module.id

///// ---------------------- OUTPUTS END ---------------------- /////
