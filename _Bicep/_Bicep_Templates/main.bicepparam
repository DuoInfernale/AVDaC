using './main.bicep'

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
param gpar_customerAbbreviation = 'xxx'

// Deployment environment (e.g. dev/test/prod). Replace as required.
param gpar_environment = 'xxxx'

// Tags applied to all deployed resources (optional). Merge keys will be applied by main.bicep.
param gpar_tags = {}

// Name for the spoke subnet that will host AVD session hosts.
param spar_snetNameSpokeAVD = ''

// Subscription-level primary deployment location.
param dpar_location = ''

// AVD-specific location (region for hostpool and session hosts). If empty, main.bicep defaults to westeurope.
param dpar_locationAVD = ''

// VNet address space for the spoke VNet (example: 10.100.0.0/20).
param dpar_spokeVnetPrefix = ''

// Spoke subnet prefix(es) for AVD (example: [ '10.100.1.0/24' ]).
param dpar_spokeSubnetPrefix = []

// Optional AVD workspace name; leave empty to use generated default.
param dpar_vdwsName = ''

// Optional AVD application group type (Desktop or RemoteApp); defaults to Desktop.
param dpar_vdagApplicationGroupType = ''

// File share name for FSLogix profiles (optional, default: fsl-profiles).
param dpar_stShareName = ''

// File share quota (GiB) for FSLogix/profile storage.
param dpar_fsshareQuota = 100

// Number of session host VMs to create.
param dpar_vmCount = 2

// Size of the session host VMs.
param dpar_vmSize = ''

// Private DNS zone name to create for privatelink resolution.
param dpar_privateDNSName = ''

// Local admin username for session hosts.
param dpar_vmlocaladminName = ''

// Local admin password for session hosts (replace before deployment; keep secure).
param dpar_vmlocaladminPassword = ''

// Object ID (Azure AD) of users who should be assigned to the Desktop Application Group.
param dpar_rbacObjectIdFullDesktopUsers = ''

// Object ID (Azure AD) of users that require RBAC access to storage (FSLogix).
param dpar_rbacObjectIdRBACAVDUsers = ''

// Object ID (Azure AD) of the AVD administrator (storage admin / elevated tasks).
param dpar_rbacObjectIdRBACAVDAdmin = ''

///// ---------------------- PARAMETERS END ---------------------- /////
