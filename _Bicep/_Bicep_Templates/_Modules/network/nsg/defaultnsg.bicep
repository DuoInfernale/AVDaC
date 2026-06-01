///// ---------------------- HEADER ---------------------- /////

// Bicep file for deploying a default Network Security Group (NSG)
//
// Authors: Michele Blum & Flavio Meyer
// Created: 01.03.2025
// Updated: 29.05.2026
// Notes:
// - This module creates a Network Security Group with AVD-oriented outbound rules based on Microsoft guidance.
// - Deploy at resource group scope (NSGs are resource-group scoped).

///// ---------------------- HEADER END ---------------------- /////

///// ---------------------- CHANGELOG ---------------------- /////

// Version: 1.0.0
// Date: 01.03.2025
// - Initial version
//
// Version: 1.1.0
// Date: 14.05.2026
// - Added rules and defaults
//
// Version: 1.2.0
// Date: 29.05.2026
// - Apply consistent formatting, parameter validation and outputs

///// ---------------------- CHANGELOG END ---------------------- /////

///// ---------------------- SCOPE ---------------------- /////

// Module must be deployed at resource group scope
targetScope = 'resourceGroup'

///// ---------------------- SCOPE END ---------------------- /////

///// ---------------------- PARAMETERS ---------------------- /////

// The name of the Network Security Group.
@description('The name of the Network Security Group.')
@minLength(1)
@maxLength(80)
param nsgName string

// The Azure region where the NSG will be deployed.
@description('The Azure region where the Network Security Group will be deployed (e.g. westeurope).')
@minLength(1)
@maxLength(64)
param nsgLocation string

// Tags to be applied to the NSG (optional).
@description('Tags to be applied to the Network Security Group.')
param nsgTags object = {}

///// ---------------------- PARAMETERS END ---------------------- /////

///// ---------------------- RESOURCES ---------------------- /////

// Network Security Group (AVD best-practice outbound rules)
resource nsg 'Microsoft.Network/networkSecurityGroups@2025-05-01' = {
  name: nsgName
  location: nsgLocation
  tags: nsgTags

  properties: {
    securityRules: [

      // ---------------------------------------------------------
      // INBOUND RULES
      // ---------------------------------------------------------
      {
        name: 'Deny-All-Inbound'
        properties: {
          priority: 4000
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }

      // ---------------------------------------------------------
      // OUTBOUND RULES
      // ---------------------------------------------------------

      {
        name: 'Deny-All-Outbound'
        properties: {
          priority: 4000
          direction: 'Outbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }

      {
        name: 'Allow-Outbound-HTTPS'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
        }
      }

      {
        name: 'Allow-Outbound-HTTP'
        properties: {
          priority: 110
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
        }
      }

      {
        name: 'Allow-Outbound-NTP'
        properties: {
          priority: 120
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Udp'
          sourcePortRange: '*'
          destinationPortRange: '123'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
        }
      }

      {
        name: 'Allow-Outbound-APNS'
        properties: {
          priority: 130
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '5223'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
        }
      }

      {
        name: 'Allow-Outbound-UDP-HTTPS'
        properties: {
          priority: 140
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Udp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
        }
      }

      {
        name: 'Allow-Outbound-ICMP-VNet'
        properties: {
          priority: 150
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Icmp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }

      {
        name: 'Allow-Outbound-TeamsOptimization'
        properties: {
          priority: 160
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Udp'
          sourcePortRange: '*'
          destinationPortRange: '3478-3481'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
        }
      }

      {
        name: 'Allow-Outbound-SMTPS'
        properties: {
          priority: 170
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '587'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
        }
      }

      {
        name: 'Allow-Outbound-IMAPS'
        properties: {
          priority: 180
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '993'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
        }
      }

      {
        name: 'Allow-Outbound-POPS'
        properties: {
          priority: 190
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '995'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
        }
      }

      {
        name: 'Allow-Outbound-IMAP'
        properties: {
          priority: 200
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '143'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
        }
      }

      {
        name: 'Allow-Outbound-SMTP'
        properties: {
          priority: 210
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '25'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
        }
      }

    ]
  }
}

///// ---------------------- RESOURCES END ---------------------- /////

///// ---------------------- OUTPUTS ---------------------- /////

// NSG Resource ID
output nsgId string = nsg.id

// NSG name
output nsgNameOutput string = nsg.name

// NSG security rules (useful for downstream checks)
output nsgSecurityRules array = nsg.properties.securityRules

///// ---------------------- OUTPUTS END ---------------------- /////
