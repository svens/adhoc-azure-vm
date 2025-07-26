targetScope = 'subscription'

param location string = 'northeurope'
param resource string
param login_ip string
param username string
@secure()
param password string

var _images = {
  'linux-dev': {
    publisher: 'Canonical'
    offer: 'ubuntu-24_04-lts'
    sku: 'server'
  }
  'windows-dev': {
    publisher: 'MicrosoftVisualStudio'
    offer: 'visualstudioplustools'
    sku: 'vs-2022-pro-general-win11-m365-gen2'
  }
  'windows-core': {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter-core'
  }
}

var _resource_parts = split(resource, '-')
var _os = toLower(_resource_parts[1])
var _variant = toLower(_resource_parts[2])
var _os_type = '${_os}-${_variant}'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resource
  location: location
}

module net './net.bicep' = {
  name: 'net'
  scope: rg
  params: {
    location: location
    os: _os
    login_ip: login_ip
  }
}

module vm './vm.bicep' = {
  name: _os_type
  scope: rg
  params: {
    location: location
    os: _os
    username: username
    password: password
    publisher: _images[_os_type].publisher
    offer: _images[_os_type].offer
    sku: _images[_os_type].sku
    nsgId: net.outputs.nsgId
    subnetId: net.outputs.subnetId
  }
}
