# Loadtesting cluster creation in Azure

Azure Infrastructure as Code (IaC) project for deploying load testing clusters using Azure Bicep templates. Creates VM clusters with dual-stack networking (IPv4/IPv6) in Azure, designed for quick deployment and management of development environments.

## Prerequisites

Before running any commands, authenticate with Azure:
```bash
# From Intune managed machine
az login

# From non-Intune machine
az login --use-device-code
```

## Architecture

### Component Structure
- **template/main.bicep**: Subscription-level orchestration template
- **template/net.bicep**: Networking resources (VNet, NSG, subnets)
- **template/vm.bicep**: Virtual machine definitions with dual-stack networking
- **template/cloud-init.yaml**: VM initialization and development tools setup
- **_common.sh**: Shared shell functions for all operations
- Individual scripts: Thin wrappers around `_common.sh` functions

### Key Features
- Dual-stack networking (IPv4/IPv6 support)
- Network access restricted to deployer's current public IP
- Standard F4s_v2 VM size with accelerated networking
- SSH key-based authentication (password auth disabled)
- Automatic password generation for initial setup
- Azure Monitor agent integration

### Resource Naming Convention
- Resource Group: `{username}-{os}-{variant}`
- Location: Hard-coded to `northeurope`
- VM Names: Based on OS type specification

### Supported Variants
- `linux-dev`: Ubuntu 24.04 LTS with development tools
- `windows-dev`: Windows 11 with Visual Studio 2022 Professional
- `windows-core`: Windows Server 2022 Core Datacenter (headless)

## Commands

All scripts accept variant parameters:

```bash
./validate [linux-dev|windows-dev|windows-core]    # Validate Bicep template syntax
./deploy [linux-dev|windows-dev|windows-core]      # Deploy cluster infrastructure
./show [linux-dev|windows-dev|windows-core]        # Display VM public IP addresses
./passwd [linux-dev|windows-dev|windows-core]      # Update VM passwords interactively
./start [linux-dev|windows-dev|windows-core]       # Start all VMs in cluster
./stop [linux-dev|windows-dev|windows-core]        # Stop VMs (billing continues)
./deallocate [linux-dev|windows-dev|windows-core]  # Deallocate VMs (stops billing)
```

## Development Environment Setup

The cloud-init configuration automatically installs:
- Build tools: build-essential, cmake, ninja-build
- Development tools: git, vim, zsh
- Custom shell configuration with aliases

## Important Notes

### Security
- SSH uses key-based authentication only (no passwords)
- Network access automatically restricted to deployer's public IP
- Secure parameter handling for VM passwords

### Cost Management
- `stop`: Stops VMs but billing continues for allocated resources
- `deallocate`: Stops billing for compute resources (preserves storage)

### Template Validation
Always run `./validate` before `./deploy` to check Bicep syntax and parameter validation.
