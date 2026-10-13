# Proxmox LXC Deployment

This repository contains the scripts used to provision a standardized Debian LXC
on a Proxmox host.

The provisioning process consists of two stages:

1. **Debian Bootstrap**
   - Updates the operating system
   - Installs the baseline package set
   - Configures locale and timezone
   - Creates the administrative user
   - Configures passwordless sudo
   - Installs the configured SSH public key
   - Optionally installs the user's dotfiles

2. **Dotfiles Bootstrap** *(optional)*
   - Clones the user's dotfiles repository
   - Checks out the shell configuration
   - Configures the bare Git repository
   - Creates the standard shell environment

The goal is that every infrastructure container starts from the same baseline
and can be reproduced from the official Debian template at any time.

---

## Quick Start

Create a baseline Debian LXC:

```bash
sudo ./sbin/bootstrap/proxmox-lxc.sh \
    --vmid 101 \
    --hostname nginx-01.darkstar.net
```

Create a Debian LXC and install the dotfiles:

```bash
sudo ./sbin/bootstrap/proxmox-lxc.sh \
    --vmid 101 \
    --hostname nginx-01.darkstar.net \
    --dotfiles
```

---

## Usage

```
proxmox-lxc.sh --vmid <id> --hostname <hostname> [options]
```

### Required

| Option | Description |
| ------ | ----------- |
| `--vmid` | Proxmox VMID |
| `--hostname` | Fully-qualified hostname |

### Optional

| Option | Default | Description |
| ------ | ------- | ----------- |
| `--cores` | `1` | Number of CPU cores |
| `--memory` | `512` | Memory (MB) |
| `--swap` | `512` | Swap (MB) |
| `--disk` | `8` | Root disk size (GB) |
| `--storage` | `local-lvm` | Root filesystem storage |
| `--bridge` | `vmbr0` | Network bridge |
| `--template` | Latest local Debian 13 template | Override LXC template |
| `--dotfiles` | disabled | Install the user's dotfiles |

---

## Deployment Process

The provisioning workflow is:

```
Official Debian Template
        │
        ▼
Create LXC
        │
        ▼
Start LXC
        │
        ▼
Push bootstrap scripts
        │
        ▼
Run debian.sh
        │
        ▼
(optional)
Run dotfiles.sh
        │
        ▼
Ready for application installation
```

---

## User Setup

The bootstrap creates a standard administrative account.

Default user:

```
raven
```

The user is configured with:

- `/bin/bash`
- member of the `sudo` group
- passwordless `sudo`
- SSH key authentication

The root account receives the password supplied during provisioning.

---

## SSH Setup

The provisioning helper installs the configured public SSH key into the
administrative user's `authorized_keys`.

Current location on the Proxmox host:

```
/opt/darkstar/keys/raven_ed25519.pub
```

The corresponding private key remains on the administrator's workstation and is
never copied to Proxmox or the LXC.

After provisioning:

```bash
ssh raven@hostname
```

Administrative access:

```bash
sudo -i
```

---

## Templates

The provisioning helper defaults to the newest locally-installed Debian 13 LXC
template.

Current template location:

```
local:vztmpl/debian-13-standard_<version>_amd64.tar.zst
```

Additional templates can be installed with:

```bash
pveam download local debian-13-standard_<version>_amd64.tar.zst
```

or from the Proxmox web interface:

```
local
└── CT Templates
    └── Templates
```

---

## Repository Layout

```
sbin/
└── bootstrap/
    ├── proxmox-lxc.sh
    ├── debian.sh
    └── dotfiles.sh
```

| Script | Purpose |
| ------ | ------- |
| `proxmox-lxc.sh` | Creates and provisions a new LXC |
| `debian.sh` | Applies the Debian baseline |
| `dotfiles.sh` | Installs the user's shell environment |

---

## Customization

The defaults are intended for small infrastructure containers.

Default configuration:

| Setting | Value |
| ------- | ----: |
| CPU | 1 core |
| Memory | 512 MB |
| Swap | 512 MB |
| Disk | 8 GB |
| Network | DHCP |
| Bridge | `vmbr0` |
| Container | Unprivileged |
| Start at boot | Enabled |

These may be overridden using the command-line options.

---

## Recommended Workflow

1. Download the latest Debian template.
2. Create the new LXC using `proxmox-lxc.sh`.
3. Create a DHCP reservation in UniFi.
4. Verify SSH access.
5. Install the application-specific software.
6. Take a snapshot before significant configuration changes.

---

## Notes

The bootstrap scripts are designed to be idempotent where practical and should
be considered the source of truth for the infrastructure baseline.

Avoid making manual changes to the baseline configuration that are not reflected
in the bootstrap scripts.
