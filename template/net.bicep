param location string
param os_type string
param login_ip string

var _login = {
  linux: {
    port: '22'
  }
  windows: {
    port: '3389'
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: 'nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-login'
        properties: {
          priority: 1001
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          destinationAddressPrefix: '*'
          destinationPortRange: _login[os_type].port
          sourceAddressPrefixes: [
            login_ip
          ]
          sourcePortRange: '*'
        }
      }
    ]
  }
}
output nsgId string = resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', 'nsg')

resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: 'vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
        'fd00:5cc3:e6f2::/48'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefixes: [
            '10.0.0.0/24'
            'fd00:5cc3:e6f2::/64'
          ]
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}
var _vnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', 'vnet')
output vnetId string = _vnetId
output subnetId string = '${_vnetId}/subnets/default'
