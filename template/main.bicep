targetScope = 'subscription'

param location string = 'northeurope'

@allowed([
  'linux-dev'
  'windows-dev'
  'windows-core'
])
param os_type string = 'linux-dev'

param login_ip string
param username string
@secure()
param password string

var _os_parts = split(os_type, '-')
var _os = toLower(_os_parts[0])
var _variant = toLower(_os_parts[1])

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${username}-${_os}-${_variant}'
  location: location
}

module net './net.bicep' = {
  name: 'net'
  scope: rg
  params: {
    location: location
    os_type: _os
    login_ip: login_ip
  }
}

module vm './vm.bicep' = {
  name: _os
  scope: rg
  params: {
    location: location
    os_type: _os
    variant: _variant
    nsgId: net.outputs.nsgId
    subnetId: net.outputs.subnetId
    username: username
    password: password
  }
}
