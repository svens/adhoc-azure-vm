# Ad-hoc Azure VM deployment

Azure Infrastructure as Code (IaC) project for deploying ad-hoc development VMs using Azure Bicep templates. Creates individual VMs with dual-stack networking (IPv4/IPv6) in Azure, designed for quick deployment and management of development environments.

## Prerequisites

Before running any commands:

1. Authenticate with Azure:
```bash
# From Intune managed machine
az login

# From non-Intune machine
az login --use-device-code
```

2. Create SSH key file:
```bash
# Generate SSH key pair if you don't have one
ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_vm

# Copy public key to template directory
cp ~/.ssh/azure_vm.pub template/ssh_key.pub
```

**Note**: The `template/ssh_key.pub` file is required before deployment and will be injected into the VM for SSH access.

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
- Resource Group: `<prefix>-<os>-<variant>` (e.g., `myproject-linux-dev`)
- Location: Hard-coded to `northeurope`
- VM Names: Based on OS type specification

### Supported Variants
- `linux-dev`: Azure Linux 3 (CBL-Mariner) with development tools
- `windows-dev`: Windows 11 with Visual Studio 2022 Professional
- `windows-core`: Windows Server 2022 Core Datacenter (headless)

### VM Configuration
- VM Size: Standard F4s_v2 with accelerated networking
- SSH authentication only (password auth disabled for Linux)
- Azure Monitor and Security agents automatically installed
- Dual-stack networking (IPv4/IPv6 public IPs)
- Network access restricted to deployer's public IP

## Commands

All scripts accept resource name in `<prefix>-<os>-<variant>` format:

```bash
./validate myproject-linux-dev     # Validate Bicep template syntax
./deploy myproject-linux-dev       # Deploy VM infrastructure  
./show myproject-linux-dev         # Display VM public IP addresses
./passwd myproject-linux-dev       # Update VM passwords interactively
./start myproject-linux-dev        # Start VM
./stop myproject-linux-dev         # Stop VM (billing continues)
./deallocate myproject-linux-dev   # Deallocate VM (stops billing)
```

**Examples**:
- `./deploy personal-linux-dev`
- `./deploy testing-windows-dev`
- `./deploy prod-windows-core`

## Development Environment Setup

### Linux VMs (Azure Linux 3)
The parameterized cloud-init configuration automatically:
- Installs packages: build-essential, cmake, ninja-build, git, vim, zsh, tmux
- Configures user account with SSH key from `template/ssh_key.pub`
- Sets up zsh with custom aliases and environment variables
- Disables SSH password authentication
- Grants sudo access without password

### Windows VMs
Pre-configured with Visual Studio 2022 Professional (windows-dev) or Server Core (windows-core).

### Agent Installation
All VMs automatically receive:
- **Azure Monitor Agent**: System monitoring and telemetry
- **Azure Security Agent**: Security monitoring and compliance

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

### SSH Access
For Linux VMs, connect using:
```bash
ssh -i ~/.ssh/azure_vm username@<vm-public-ip>
```

Where `username` is your local username and the VM IP is shown by `./show`.
