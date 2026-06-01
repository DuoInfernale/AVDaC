///// ---------------------- HEADER ---------------------- /////

// Bicep file for deploying a Storage Account with Azure Files (Premium FileStorage SKU).
//
// Authors: Michele Blum & Flavio Meyer
// Created: 01.03.2025
// Updated: 29.05.2026
// Notes:
// - This module deploys a storage account, configures file service settings and creates a file share.
// - Deploy this module at resource group scope (storage accounts are resource-group scoped).
// - Validate storage account and file share names in CI/pipeline (Bicep has no regex param decorator).

///// ---------------------- HEADER END ---------------------- /////

///// ---------------------- CHANGELOG ---------------------- /////

// Version: 1.0.0
// Date: 01.03.2025
// - Initial version
//
// Version: 1.1.0
// Date: 14.05.2026
// - Added defaults and extra SMB settings
//
// Version: 1.2.0
// Date: 29.05.2026
// - Apply consistent formatting, parameter validation and outputs

///// ---------------------- CHANGELOG END ---------------------- /////

///// ---------------------- SCOPE ---------------------- /////

// This module is intended to be deployed at resource group scope.
// If you need subscription-scope behavior, call this module with scope: resourceGroup('<rgName>').
///// ---------------------- SCOPE END ---------------------- /////

///// ---------------------- PARAMETERS ---------------------- /////

// Storage account name (lowercase letters and numbers, 3-24 chars).
@description('Storage account name (lowercase letters and numbers only, 3-24 characters). Validate with CI regex ^[a-z0-9]{3,24}$')
@minLength(3)
@maxLength(24)
param saName string

// Deployment location (Azure region)
@description('Azure region where the storage account will be created (for example: westeurope).')
@minLength(1)
@maxLength(64)
param saLocation string

// Tags applied to all resources (optional)
@description('Tags applied to the storage account and related resources.')
param saTags object = {}

// File share name (Azure Files)
@description('File share name for Azure Files (3-63; lowercase letters, numbers, hyphens). Validate with CI regex ^(?!-)(?!.*--)[a-z0-9-]{3,63}(?<!-)$')
@minLength(3)
@maxLength(63)
param fsName string

// File share quota in GB
@description('File share quota (GiB).')
@minValue(1)
param fsQuota int

// Storage SKU (default Premium_ZRS)
@description('Storage SKU name (e.g., Premium_ZRS).')
param saSkuName string = 'Premium_ZRS'

// Storage kind (FileStorage is expected for premium file shares)
@description('Storage account kind. Use FileStorage for Azure Files Premium.')
param saKind string = 'FileStorage'

// Allowed copy scope for storage operations
@description('Allowed copy scope for the storage account.')
param saAllowedCopyScope string = 'PrivateLink'

// Default share permission for Azure Files (None | Change | Full etc. depending on API expectations)
@description('Default share permission for Azure Files (e.g., None).')
param saDefaultSharePermission string = 'None'

// Directory service options for identity-based authentication (AADKERB | AD)
@description('Directory service options for Azure Files identity-based authentication (e.g., AADKERB).')
param saDirectoryServiceOptions string = 'AADKERB'

// DNS endpoint type
@description('DNS endpoint type (Standard or AzureDNSZone).')
param saDnsEndpointType string = 'Standard'

// Encryption key source
@description('Encryption key source for the storage account.')
param saEncryptionKeySource string = 'Microsoft.Storage'

// Minimum TLS version
@description('Minimum TLS version for the storage account.')
param saMinimumTlsVersion string = 'TLS1_2'

// Public network access setting
@description('Public network access setting for the storage account (Enabled or Disabled).')
param saPublicNetworkAccess string = 'Disabled'

// SMB authentication settings (strings passed to file service config)
@description('SMB authentication methods used by the file service.')
param smbAuthenticationMethods string = 'Kerberos; NTLMv2'

@description('SMB channel encryption algorithms.')
param smbChannelEncryption string = 'AES-256-GCM; AES-128-GCM'

@description('SMB versions supported by the file service.')
param smbVersions string = 'SMB3.1.1'

// Root squash mode for file share (NoRootSquash | RootSquash | AllSquash)
@description('Root squash mode for the file share.')
param fsRootSquash string = 'NoRootSquash'

// RBAC role IDs (full resource id or provider shortcut). Defaults target Storage File Data roles.
@description('Role definition id for storage admin (Storage File Data Privileged Contributor).')
param roleIdAdmin string = '/providers/Microsoft.Authorization/roleDefinitions/69566ab7-960f-475b-8e7c-b3118f30c6bd'

@description('Role definition id for storage user (Storage File Data SMB Share Contributor).')
param roleIdUser string = '/providers/Microsoft.Authorization/roleDefinitions/0c867c2a-1d8c-454a-a3db-ab2ea1bdc8bb'

// RBAC principal IDs (objectIds of user/group/service principal)
@description('Principal (object) id to assign the admin role to.')
@minLength(1)
param rbacPrincipalAdmin string

@description('Principal (object) id to assign the user role to.')
@minLength(1)
param rbacPrincipalUser string

// RBAC principal type (User, Group, ServicePrincipal)
@description('Principal type for role assignments (User, Group, ServicePrincipal).')
param rbacPrincipalType string = 'Group'

///// ---------------------- PARAMETERS END ---------------------- /////

///// ---------------------- VARIABLES ---------------------- /////

///// ---------------------- VARIABLES END ---------------------- /////

///// ---------------------- RESOURCES ---------------------- /////

// Storage Account
resource storageaccount_module 'Microsoft.Storage/storageAccounts@2025-08-01' = {
  name: saName
  location: saLocation
  tags: saTags

  sku: {
    name: saSkuName
  }

  kind: saKind

  properties: {
    allowBlobPublicAccess: false
    allowCrossTenantReplication: false
    allowedCopyScope: saAllowedCopyScope
    allowSharedKeyAccess: true

    azureFilesIdentityBasedAuthentication: {
      defaultSharePermission: saDefaultSharePermission
      directoryServiceOptions: saDirectoryServiceOptions
    }

    dnsEndpointType: saDnsEndpointType

    encryption: {
      keySource: saEncryptionKeySource
      services: {
        file: {
          enabled: true
          keyType: 'Account'
        }
      }
      requireInfrastructureEncryption: true
    }

    minimumTlsVersion: saMinimumTlsVersion
    publicNetworkAccess: saPublicNetworkAccess
    supportsHttpsTrafficOnly: true
  }
}

// File Service settings (protocol/SMB config and retention)
resource fileservice_module 'Microsoft.Storage/storageAccounts/fileServices@2025-08-01' = {
  name: 'default'
  parent: storageaccount_module
  properties: {
    protocolSettings: {
      smb: {
        authenticationMethods: smbAuthenticationMethods
        channelEncryption: smbChannelEncryption
        multichannel: {
          enabled: true
        }
        versions: smbVersions
      }
    }
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
      allowPermanentDelete: false
    }
  }
}

// File Share
resource fileshare_module 'Microsoft.Storage/storageAccounts/fileServices/shares@2025-08-01' = {
  name: fsName
  parent: fileservice_module
  properties: {
    enabledProtocols: 'SMB'
    shareQuota: fsQuota
    rootSquash: fsRootSquash
    metadata: {
      name: fsName
    }
  }
}

// RBAC: Admin role assignment on the storage account
resource storageaccountroleassignmentadmin_module 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(rbacPrincipalAdmin)) {
  name: guid(storageaccount_module.id, roleIdAdmin, rbacPrincipalAdmin)
  scope: storageaccount_module
  properties: {
    roleDefinitionId: roleIdAdmin
    principalId: rbacPrincipalAdmin
    principalType: rbacPrincipalType
  }
}

// RBAC: User role assignment on the storage account
resource storageaccountroleassignmentuser_module 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(rbacPrincipalUser)) {
  name: guid(storageaccount_module.id, roleIdUser, rbacPrincipalUser)
  scope: storageaccount_module
  properties: {
    roleDefinitionId: roleIdUser
    principalId: rbacPrincipalUser
    principalType: rbacPrincipalType
  }
}

///// ---------------------- RESOURCES END ---------------------- /////

///// ---------------------- OUTPUTS ---------------------- /////

// Storage Account Resource ID
output storageAccountId string = storageaccount_module.id

// Storage Account Name
output storageAccountName string = storageaccount_module.name

// File Service id
output fileServiceId string = fileservice_module.id

// File Share Resource ID
output fileShareId string = fileshare_module.id

// Role assignment ids (may be empty if principal not provided)
output roleAssignmentAdminId string = storageaccountroleassignmentadmin_module.id
output roleAssignmentUserId string = storageaccountroleassignmentuser_module.id

///// ---------------------- OUTPUTS END ---------------------- /////

///// ---------------------- END OF BICEP FILE ---------------------- /////
