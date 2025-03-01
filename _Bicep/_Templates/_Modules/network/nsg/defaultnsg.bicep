///// ---------------------- HEADER ---------------------- /////

// Bicep file for deploying the default network security group
// Author: Michele Blum & Flavio Meyer
// Date: 01.03.2025

///// ---------------------- HEADER END ---------------------- /////


///// ---------------------- PARAMETERS ---------------------- /////

// The name of the network security group to be created
@description('The name of the network security group.')
param nsgName string

// The location where the network security group will be deployed
@description('The location of the network security group.')
param nsgLocation string

// Tags to be applied to the network security group
@description('Tags to be applied to the network security group.')
param nsgTags object

///// ---------------------- PARAMETERS END ---------------------- /////


///// ---------------------- RESOURCES ---------------------- /////

// Define the 'network security group' resource
@description('The NSG for the AVD subnet was builit regarding the Microsoft best practices. Source: https://learn.microsoft.com/azure/virtual-desktop/required-fqdn-endpoint?tabs=azure')
resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: nsgName
  location: nsgLocation
  tags: nsgTags
  properties: {
    securityRules: [
      {
        name: 'DefaultInboundBlockAll'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4000
          direction: 'Inbound'
        }
      }
      {
        name: 'DefaultOutboundBlockAll'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4000
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowVnetOutboundHTTPS'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowVnetOutboundHTTP'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 110
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowVnetOutboundNTP'
        properties: {
          protocol: 'UDP'
          sourcePortRange: '*'
          destinationPortRange: '123'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 120
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowVnetOutboundAPNS'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '5223'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 130
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowVnetOutboundUDPHTTPS'
        properties: {
          protocol: 'UDP'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 140
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowVnetICMP'
        properties: {
          protocol: 'ICMP'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 150
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowVnetOutboundTeamsOptimization'
        properties: {
          protocol: 'UDP'
          sourcePortRange: '*'
          destinationPortRange: '3478-3481'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 160
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowVnetOutboundSTMPS'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '587'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 170
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowVnetOutboundIMAPS'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '993'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 180
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowVnetOutboundPOPS'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '995'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 190
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowVnetOutboundIMAP'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '143'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 200
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowVnetOutboundSMTP'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '25'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 210
          direction: 'Outbound'
        }
      }
    ]
  }
}

///// ---------------------- RESOURCES END ---------------------- /////


///// ---------------------- OUTPUTS ---------------------- /////

// Output the network security group ID
output defaultNSGId string = nsg.id

///// ---------------------- OUTPUTS END ---------------------- /////


///// ---------------------- END OF BICEP FILE ---------------------- /////
