# Ad-hoc Azure VM deployment

Azure Infrastructure as Code (IaC) project for deploying ad-hoc development VMs using Azure Bicep templates and CMake. Creates individual VMs with dual-stack networking (IPv4/IPv6) in Azure, designed for quick deployment and management of development environments.

## Prerequisites

Before running any commands:

1. **Authenticate with Azure**:
```bash
# From Intune managed machine
az login

# From non-Intune machine
az login --use-device-code
```

2. **Install required tools**:
   - Azure CLI (`az`)
   - CMake (3.10 or higher)
   - Your favorite build system (Ninja used in this example)
   - SSH client

## Quick Start

```bash
# Create and configure project
mkdir myproject-linux-dev && cd myproject-linux-dev
cmake .. -DVM_PROJECT=myproject -DVM_OS=linux -DVM_VARIANT=dev -G Ninja

# VM is automatically deployed during cmake configure step
# Use ninja targets for VM management:
ninja show     # Show all VM properties
ninja login    # SSH into the VM
ninja passwd   # Generate new random password
ninja start    # Start VM
ninja stop     # Stop VM
ninja rm       # Remove all Azure resources
```

## Configuration Options

Configure your deployment with CMake variables:

```bash
cmake .. -G Ninja \
  -DVM_PROJECT=myproject \
  -DVM_OS=linux \
  -DVM_VARIANT=dev \
  -DVM_USERNAME=myuser \
  -DVM_LOCATION=eastus
```

### Available Options
- **VM_PROJECT**: Project name (default: `$USER`)
- **VM_OS**: Operating system - `linux` or `windows` (default: `linux`)
- **VM_VARIANT**: Variant - `dev` or `core` (default: `dev`)
- **VM_USERNAME**: VM username (default: `$USER`)
- **VM_LOCATION**: Azure region (default: `northeurope`)

### Derived Settings
- **Resource Group**: `${VM_PROJECT}-${VM_OS}-${VM_VARIANT}`
- **VM Name**: `${VM_OS}`
- **SSH Keys**: Auto-generated in build directory

## Architecture

### Component Structure
- **template/*.bicep.in**: Bicep template sources with CMake variables
- **template/cloud-init.yaml.in**: VM initialization template
- **scripts/update_password.cmake**: Password update logic
- **CMakeLists.txt**: Build system configuration

### Key Features
- **Configure-time deployment**: VM deployed automatically during `cmake` step
- **Dual-stack networking**: IPv4/IPv6 support
- **Network security**: Access restricted to deployer's current public IP
- **SSH key authentication**: Auto-generated SSH keys, no password auth
- **Random passwords**: Strong passwords for Windows VMs
- **Azure monitoring**: Azure Monitor and Security agents pre-installed

### Supported VM Types
- **linux-dev**: Azure Linux 3 (CBL-Mariner) with development tools
- **windows-dev**: Windows 11 with Visual Studio 2022 Professional
- **windows-core**: Windows Server 2022 Core Datacenter (headless)

## Buildsystem Targets

| Target | Description |
|--------|-------------|
| `show` | Display all VM configuration and discovered properties |
| `login` | SSH into the VM using auto-generated keys |
| `passwd` | Generate and set new random VM password |
| `start` | Start the VM |
| `stop` | Stop the VM (billing continues) |
| `rm` | Remove all Azure resources |

## Development Environment Setup

### Linux VMs (Azure Linux 3)
The cloud-init configuration automatically:
- Installs development tools: build-essential, cmake, ninja-build, git, vim, zsh, tmux
- Configures user account with auto-generated SSH key
- Sets up zsh with custom aliases and environment variables
- Disables SSH password authentication
- Grants passwordless sudo access

### Windows VMs
Pre-configured with Visual Studio 2022 Professional (windows-dev) or Server Core (windows-core).

### SSH Access
For Linux VMs, use the generated login target:
```bash
ninja login
```

Or manually:
```bash
ssh -i ssh_key -o StrictHostKeyChecking=no username@vm-ip
```

## File Structure

```
├── CMakeLists.txt             # Main build configuration
├── template/                  # Template sources
│   ├── main.bicep.in          # Main deployment template
│   ├── net.bicep.in           # Networking configuration
│   ├── vm.bicep.in            # VM configuration
│   └── cloud-init.yaml.in     # VM initialization
├── scripts/
│   └── update_password.cmake  # Password management
└── build-dir/                 # Generated during cmake
    ├── template/              # Configured Bicep files
    ├── ssh_key*               # Generated SSH keys
    └── vm.conf                # Discovered VM properties
```

## Security Notes

- **SSH Authentication**: Uses auto-generated RSA-4096 keys only
- **Network Access**: Automatically restricted to deployer's public IP
- **Password Security**: Random 20-character passwords with special characters
- **Secure Storage**: Passwords shown only once, not stored anywhere

## Cost Management

- **`ninja stop`**: Stops VM but billing continues for allocated resources
- **`ninja rm`**: Completely removes all resources and stops all billing
- VMs use Standard F4s_v2 size with accelerated networking

## Troubleshooting

### Re-deployment
If you need to re-deploy (e.g., after `ninja rm`):
```bash
# Clear CMake cache and re-configure
rm -rf build-dir
mkdir build-dir && cd build-dir
cmake .. -G Ninja  # VM will be deployed again
```

### SSH Issues
```bash
ninja show         # Check VM_IP is set
ninja start        # Ensure VM is running
ninja login        # Use managed SSH connection
```
