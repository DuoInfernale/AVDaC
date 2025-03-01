///// ---------------------- HEADER ---------------------- /////

// Bicep file for deploying a storage account with Azure Files
// Author: Michele Blum & Flavio Meyer
// Date: 01.03.2025

///// ---------------------- HEADER END ---------------------- /////


///// ---------------------- PARAMETERS ---------------------- /////

// The name of the storage account to be created.
@description('The name of the storage account.')
param stName string

// The Azure region where the storage account will be created.
@description('The location of the storage account.')
param stLocation string

// Tags to be applied to the storage account for resource management and organization.
@description('Tags to be applied to the storage account.')
param stTags object

// The name of the file share to be created within the file service.
@description('The name of the file share.')
param shareName string

// The storage quota for the file share in gigabytes.
@description('The quota for the file share in GB.')
param shareQuota int

// The SKU name for the storage account, defining the performance and replication type.
@description('The SKU name for the storage account.')
param stSkuName string = 'Premium_ZRS'

// The kind of the storage account, specifying the type of storage.
@description('The kind of the storage account.')
param stKind string = 'FileStorage'

// The allowed copy scope for the storage account, specifying the authentication method for copy operations.
@description('The allowed copy scope for the storage account.')
param allowedCopyScope string = 'PrivateLink'

// The default share permission for Azure Files identity-based authentication.
@description('The default share permission for Azure Files identity-based authentication.')
param defaultSharePermission string = 'None'

// The directory service options for Azure Files identity-based authentication.
@description('The directory service options for Azure Files identity-based authentication.')
param directoryServiceOptions string = 'AADKERB'

// The DNS endpoint type for the storage account.
@description('The DNS endpoint type for the storage account.')
param dnsEndpointType string = 'Standard'

// The key source for encryption, specifying where the encryption keys are managed.
@description('The key source for encryption.')
param encryptionKeySource string = 'Microsoft.Storage'

// The minimum TLS version required for the storage account.
@description('The minimum TLS version for the storage account.')
param minimumTlsVersion string = 'TLS1_2'

// The public network access setting for the storage account, specifying whether public access is allowed.
@description('The public network access setting for the storage account.')
param publicNetworkAccess string = 'Disabled'

// The SMB authentication methods for the file service.
@description('The SMB authentication methods for the file service.')
param smbAuthenticationMethods string = 'NTLMv2'

// The SMB channel encryption for the file service.
@description('The SMB channel encryption for the file service.')
param smbChannelEncryption string = 'AES-256-GCM; AES-128-GCM'

// The SMB versions supported by the file service.
@description('The SMB versions for the file service.')
param smbVersions string = 'SMB3.1.1'

// The root squash setting for the file share, specifying how root access is handled.
@description('The root squash setting for the file share.')
param rootSquash string = 'NoRootSquash'

// The role definition ID for the RBAC role assignment for administrators.
@description('The role definition ID for the RBAC role assignment for administrators.')
param roleDefinitionIdAdmin string = '/providers/Microsoft.Authorization/roleDefinitions/69566ab7-960f-475b-8e7c-b3118f30c6bd' // Storage File Data Privileged Contributor

// The role definition ID for the RBAC role assignment for users.
@description('The role definition ID for the RBAC role assignment for users.')
param roleDefinitionIdUser string = '/providers/Microsoft.Authorization/roleDefinitions/0c867c2a-1d8c-454a-a3db-ab2ea1bdc8bb' // Storage File Data SMB Share Contributor

// The object ID of the RBAC admin principal to assign permissions to.
@description('The object ID of the RBAC admin principal.')
param rbacObjectIdAdmin string

// The object ID of the RBAC user principal to assign permissions to.
@description('The object ID of the RBAC user principal.')
param rbacObjectIdUser string

// The principal type for the RBAC role assignment.
@description('The principal type for the RBAC role assignment.')
param rbacPrincipalType string = 'Group'

///// ---------------------- PARAMETERS END ---------------------- /////


///// ---------------------- RESOURCES ---------------------- /////

// Define the 'storage account' resource
resource fsstorageaccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: stName
  location: stLocation
  tags: stTags
  sku: {
    name: stSkuName
  }
  kind: stKind
  properties: {
    allowBlobPublicAccess: false
    allowCrossTenantReplication: false
    allowedCopyScope: allowedCopyScope
    allowSharedKeyAccess: true
    azureFilesIdentityBasedAuthentication: {
      defaultSharePermission: defaultSharePermission
      directoryServiceOptions: directoryServiceOptions
    }
    dnsEndpointType: dnsEndpointType
    encryption: {
      keySource: encryptionKeySource
      requireInfrastructureEncryption: true
      services: {
        file: {
          enabled: true
          keyType: 'Account'
        }
      }
    }
    minimumTlsVersion: minimumTlsVersion
    publicNetworkAccess: publicNetworkAccess
    supportsHttpsTrafficOnly: true
  }
}

// Define the 'file service' resource
resource fileservice 'Microsoft.Storage/storageAccounts/fileServices@2023-05-01' = {
  parent: fsstorageaccount
  name: 'default'
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
      allowPermanentDelete: false
      days: 7
      enabled: true
    }
  }
}

// Define the 'file share' resource
resource share 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-05-01' = {
  parent: fileservice
  name: shareName
  properties: {
    enabledProtocols: 'SMB'
    metadata: {
      name: shareName
    }
    rootSquash: rootSquash
    shareQuota: shareQuota
  }
}

// Assign RBAC admin permissions to the 'storage account' resource
resource shareroleassignmentadmin 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(fsstorageaccount.id, roleDefinitionIdAdmin, rbacObjectIdAdmin)
  scope: fsstorageaccount
  properties: {
    roleDefinitionId: roleDefinitionIdAdmin
    principalId: rbacObjectIdAdmin
    principalType: rbacPrincipalType
  }
}

// Assign RBAC user permissions to the 'storage account' resource
resource shareroleassignmentuser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(fsstorageaccount.id, roleDefinitionIdUser, rbacObjectIdUser)
  scope: fsstorageaccount
  properties: {
    roleDefinitionId: roleDefinitionIdUser
    principalId: rbacObjectIdUser
    principalType: rbacPrincipalType
  }
}

///// ---------------------- RESOURCES END ---------------------- /////


///// ---------------------- OUTPUTS ---------------------- /////

// Output the storage account ID
output storageAccountId string = fsstorageaccount.id

// Output the storage account name
output storageAccountName string = fsstorageaccount.name

///// ---------------------- OUTPUTS END ---------------------- /////


///// ---------------------- END OF BICEP FILE ---------------------- /////
