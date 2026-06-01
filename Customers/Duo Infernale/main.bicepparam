using '../../_Bicep/_Bicep_Templates/main.bicep'

///// ---------------------- HEADER ---------------------- /////

// Bicep parameters file for deploying the AVD environment (parameters for main.bicep).
// This file provides values for the global, static and dynamic parameters defined in main.bicep.
//
// Authors: Michele Blum & Flavio Meyer
// Created: 29.05.2026
// Notes: Replace placeholder values before deployment. Keep secrets secure.

///// ---------------------- HEADER END ---------------------- /////

///// ---------------------- PARAMETERS ---------------------- /////

// Short customer abbreviation used in naming (max 3 chars). Replace with your customer code.
param gpar_customerAbbreviation = 'hfa'

// Deployment environment (e.g. dev/test/prod). Replace as required.
param gpar_environment = 'prod'

// Tags applied to all deployed resources (optional). Merge keys will be applied by main.bicep.
param gpar_tags = {
  Project: 'ELNL'
  Owner:  'Michele Blum'
}

// Name for the spoke subnet that will host AVD session hosts.
param spar_snetNameSpokeAVD = 'hfa-subnet-avd'

// Subscription-level primary deployment location.
param dpar_location = 'switzerlandnorth'

// AVD-specific location (region for hostpool and session hosts). If empty, main.bicep defaults to westeurope.
param dpar_locationAVD = 'westeurope'

// VNet address space for the spoke VNet (example: 10.100.0.0/20).
param dpar_spokeVnetPrefix = '10.100.0.0/20'

// Spoke subnet prefix(es) for AVD (example: [ '10.100.1.0/24' ]).
param dpar_spokeSubnetPrefix = [
  '10.100.1.0/24'
]

// Optional AVD workspace name; leave empty to use generated default.
param dpar_vdwsName = 'hfa-avd-workspace'

// Optional AVD application group type (Desktop or RemoteApp); defaults to Desktop.
param dpar_vdagApplicationGroupType = 'Desktop'

// Optional file share name for FSLogix profiles; default is 'fsl-profiles'.
param dpar_stShareName = 'hfa-fslogix-profiles'

// File share quota (GiB) for FSLogix/profile storage.
param dpar_fsshareQuota = 100

// Number of session host VMs to create.
param dpar_vmCount = 2

// Size of the session host VMs.
param dpar_vmSize = 'Standard_D2as_v6'

// Private DNS zone name to create for privatelink resolution.
param dpar_privateDNSName = 'privatelink.file.core.windows.net'

// Local admin username for session hosts.
param dpar_vmlocaladminName = 'locadm'

// Local admin password for session hosts (replace before deployment; keep secure).
param dpar_vmlocaladminPassword = 'gXARLcKF!vZK4dxx'

// Object ID (Azure AD) of users who should be assigned to the Desktop Application Group.
param dpar_rbacObjectIdFullDesktopUsers = '2df2944a-1d54-48e4-a3d9-b01140647c5a'

// Object ID (Azure AD) of users that require RBAC access to storage (FSLogix).
param dpar_rbacObjectIdRBACAVDUsers = '2df2944a-1d54-48e4-a3d9-b01140647c5a'

// Object ID (Azure AD) of the AVD administrator (storage admin / elevated tasks).
param dpar_rbacObjectIdRBACAVDAdmin = 'ce913c73-55c5-4df4-9401-1cdf9b9f9e66'

///// ---------------------- PARAMETERS END ---------------------- /////
