param location string
param os string
param nsgId string
param subnetId string

param username string
@secure()
param password string

param publisher string
param offer string
param sku string

var _os_agents = {
  linux: {
    monitor_agent_type: 'AzureMonitorLinuxAgent'
    monitor_agent_version: '1.21'
    security_agent_type: 'AzureSecurityLinuxAgent'
    security_agent_version: '2.30'
  }
  windows: {
    monitor_agent_type: 'AzureMonitorWindowsAgent'
    monitor_agent_version: '1.0'
    security_agent_type: 'AzureSecurityWindowsAgent'
    security_agent_version: '1.8'
  }
}


resource vm 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: os
  location: location
  properties: {
    osProfile: {
      computerName: os
      adminUsername: username
      adminPassword: password
      allowExtensionOperations: true
      customData: loadFileAsBase64('cloud-init.yaml')
    }
    hardwareProfile: {
      vmSize: 'Standard_F4s_v2'
    }
    storageProfile: {
      imageReference: {
        publisher: publisher
        offer: offer
        sku: sku
        version: 'latest'
      }
      osDisk: {
        name: 'disk'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vm_nic.id
        }
      ]
    }
  }
}

resource vm_pip_v4 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: 'ipv4'
  location: location
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
  }
}

resource vm_pip_v6 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: 'ipv6'
  location: location
  properties: {
    publicIPAddressVersion: 'IPv6'
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
  }
}

resource vm_nic 'Microsoft.Network/networkInterfaces@2021-03-01' = {
  name: 'nic'
  location: location
  properties: {
    enableAcceleratedNetworking: true
    enableIPForwarding: false
    ipConfigurations: [
      {
        name: 'ipv4-config'
        properties: {
          privateIPAddressVersion: 'IPv4'
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: vm_pip_v4.id
          }
          subnet: {
            id: subnetId
          }
        }
      }
      {
        name: 'ipv6-config'
        properties: {
          privateIPAddressVersion: 'IPv6'
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: vm_pip_v6.id
          }
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgId
    }
  }
}

resource vm_monitor_agent 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = {
  parent: vm
  name: 'monitor_agent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: _os_agents[os].monitor_agent_type
    typeHandlerVersion: _os_agents[os].monitor_agent_version
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      genevaConfiguration: {
        enable: true
      }
    }
  }
}

resource vm_security_agent 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = {
  parent: vm
  name: 'security_agent'
  location: location
  dependsOn: [
    vm_monitor_agent
  ]
  properties: {
    publisher: 'Microsoft.Azure.Security.Monitoring'
    type: _os_agents[os].security_agent_type
    typeHandlerVersion: _os_agents[os].security_agent_version
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {}
  }
}
