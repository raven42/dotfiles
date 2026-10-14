# Proxmox LXC Deployment

This directory contains the tooling used to create and maintain standardized Debian LXC containers on a Proxmox host.

The deployment model is intentionally split into two layers:

1. **Debian baseline**
   - Updates the operating system
   - Installs the standard administration package set
   - Configures locale and timezone
   - Creates/configures the administrative user
   - Installs the configured SSH public key
   - Configures passwordless `sudo`
   - Enables SSH

2. **Setup modules**
   - Add optional capabilities or service prerequisites
   - Can be applied during container creation or later
   - Can be re-applied to existing containers
   - Are tracked inside the LXC with the Git commit used when they were applied

Examples of setup modules include:

- `dotfiles`
- `ansible-managed`
- `nut`

The goal is for infrastructure containers to be reproducible from the official Debian LXC template while still allowing individual services to layer only the components they need.

---

## Quick Start

List available setup modules:

```bash
proxmox-lxc list
```

Create a basic Debian container:

```bash
proxmox-lxc create \
    --vmid 101 \
    --hostname example-01.darkstar.net
```

Create a NUT server with the standard shell environment and Ansible prerequisites:

```bash
proxmox-lxc create \
    --vmid 100 \
    --hostname nut-01.darkstar.net \
    --setup dotfiles \
    --setup ansible-managed \
    --setup nut
```

Apply or re-apply a setup module to an existing container:

```bash
proxmox-lxc apply \
    --vmid 100 \
    --setup nut
```

Check the setup state of a container:

```bash
proxmox-lxc status --vmid 100
```

Show detailed status information:

```bash
proxmox-lxc status --vmid 100 --verbose
```

---

## Usage

The main command is:

```text
proxmox-lxc <command> [options]
```

Available commands:

| Command | Description |
| --- | --- |
| `create` | Create a new LXC and apply the Debian baseline/setup modules |
| `apply` | Re-apply the Debian baseline and selected setup modules to an existing LXC |
| `list` | List available setup modules |
| `status` | Show setup modules previously applied to an LXC |
| `help` | Display general command help |

Command-specific help is available with:

```bash
proxmox-lxc <command> --help
```

### Create

```text
proxmox-lxc create --vmid <id> --hostname <hostname> [options]
```

Required:

| Option | Description |
| --- | --- |
| `--vmid <id>` | Proxmox VMID |
| `--hostname <hostname>` | LXC hostname/FQDN |

Container options:

| Option | Default | Description |
| --- | --- | --- |
| `--cores <n>` | `1` | Number of CPU cores |
| `--memory <mb>` | `512` | Memory in MB |
| `--swap <mb>` | `512` | Swap in MB |
| `--disk <gb>` | `8` | Root disk size in GB |
| `--storage <id>` | `local-lvm` | Root filesystem storage |
| `--bridge <bridge>` | `vmbr0` | Proxmox network bridge |
| `--template <name>` | Latest local Debian 13 template | Override the LXC template |

Provisioning options:

| Option | Default | Description |
| --- | --- | --- |
| `--user <user>` | `raven` | Administrative Linux user |
| `--ssh-key <path>` | `/opt/darkstar/keys/raven_ed25519.pub` | Public SSH key installed for the admin user |
| `--setup <name>` | none | Apply a setup module; may be specified multiple times |

During creation, the script prompts for a root password. This password is used for console/recovery access inside the LXC and is not stored in the repository.

Example:

```bash
proxmox-lxc create \
    --vmid 100 \
    --hostname nut-01.darkstar.net \
    --setup dotfiles \
    --setup ansible-managed \
    --setup nut
```

### Apply

```text
proxmox-lxc apply --vmid <id> [options]
```

The `apply` command operates on an existing LXC.

It:

1. Starts the container if necessary
2. Re-applies the Debian baseline
3. Applies each requested setup module
4. Updates the setup state markers for successfully applied modules

Options:

| Option | Default | Description |
| --- | --- | --- |
| `--vmid <id>` | required | Existing Proxmox VMID |
| `--user <user>` | `raven` | Administrative Linux user |
| `--ssh-key <path>` | `/opt/darkstar/keys/raven_ed25519.pub` | Public SSH key |
| `--setup <name>` | none | Setup module to apply; repeatable |

Example:

```bash
proxmox-lxc apply \
    --vmid 100 \
    --setup ansible-managed \
    --setup nut
```

### List

List available setup modules:

```bash
proxmox-lxc list
```

Show the filesystem location of each setup module:

```bash
proxmox-lxc list --verbose
```

Setup modules are discovered automatically from:

```text
setup/*.sh
setup/services/*.sh
```

Adding another script to either location automatically makes it available to `--setup` and Bash completion.

### Status

Show the setup state recorded for an LXC:

```bash
proxmox-lxc status --vmid 100
```

The normal output is intentionally compact and compares the Git commit used when each module was applied with the current commit on the upstream repository.

Example:

```text
VMID 100  nut-01.darkstar.net

MODULE                 SOURCE     ORIGIN     STATUS
dotfiles               a42c9de    a42c9de    current
ansible-managed        a42c9de    b81e141    behind
nut                     b81e141    b81e141    current
```

Possible status values include:

| Status | Meaning |
| --- | --- |
| `current` | Applied commit matches the current origin commit |
| `behind` | The module was applied from an older commit |
| `ahead` | The applied commit is newer than origin |
| `diverged` | The applied commit and origin are on different histories |
| `unknown` | Commit relationship could not be determined |

For full details:

```bash
proxmox-lxc status --vmid 100 --verbose
```

The status command performs a `git fetch origin` before comparing commits. If the fetch fails, status information may be reported as `unknown`.

---

## User Setup

The Debian baseline creates or updates a standard administrative account.

Default:

```text
raven
```

The account is configured with:

- `/bin/bash`
- membership in the `sudo` group
- passwordless `sudo`
- SSH public-key authentication

Administrative access after login:

```bash
sudo -i
```

The user can be overridden during creation or apply:

```bash
proxmox-lxc create \
    --vmid 101 \
    --hostname example-01.darkstar.net \
    --user anotheruser
```

The root account is separate from the administrative account.

When a new container is created, the deployment process prompts for a root password so that the Proxmox console remains usable for recovery even if SSH access is unavailable.

---

## SSH Setup

The bootstrap process installs a public SSH key into the administrative user's:

```text
~/.ssh/authorized_keys
```

The default public key location on the Proxmox host is:

```text
/opt/darkstar/keys/raven_ed25519.pub
```

The corresponding private key remains on the administrator's workstation and should never be copied to Proxmox or into the LXC.

A public key can safely be copied to the Proxmox host with, for example:

```bash
sudo mkdir -p /opt/darkstar/keys
sudo cp raven_ed25519.pub /opt/darkstar/keys/
```

The key location can be overridden:

```bash
proxmox-lxc create \
    --vmid 101 \
    --hostname example-01.darkstar.net \
    --ssh-key /path/to/another_key.pub
```

After provisioning:

```bash
ssh raven@example-01.darkstar.net
```

Then elevate when necessary:

```bash
sudo -i
```

---

## Setup Modules

Setup modules are optional scripts layered on top of the Debian baseline.

Current layout:

```text
setup/
├── ansible-managed.sh
├── dotfiles.sh
└── services/
    └── nut.sh
```

A setup module is invoked by its filename without `.sh`.

For example:

```text
setup/dotfiles.sh
```

is invoked with:

```bash
--setup dotfiles
```

and:

```text
setup/services/nut.sh
```

is invoked with:

```bash
--setup nut
```

Multiple modules can be applied in the order specified:

```bash
proxmox-lxc apply \
    --vmid 100 \
    --setup dotfiles \
    --setup ansible-managed \
    --setup nut
```

Setup scripts should be written so they can safely be run more than once where practical.

### `dotfiles`

Installs the standard user shell environment using the bare Git repository model.

The setup:

- clones the dotfiles repository into `~/.cfg`
- configures the home directory as the Git work tree
- backs up conflicting shell files
- configures the global excludes file
- checks out the managed dotfiles

### `ansible-managed`

Installs the prerequisites needed for the LXC to be managed by Ansible.

Ansible does not require a resident agent. The module installs the normal managed-host requirements such as:

- Python 3
- `python3-apt`
- SSH
- `sudo`

### `nut`

Installs the Network UPS Tools packages required for a NUT server/client environment.

The setup module installs the software only. Service configuration is expected to be managed separately, for example through Ansible.

---

## Setup State Tracking

Successfully applied setup modules are tracked inside each LXC under:

```text
/var/lib/darkstar-bootstrap/
```

Layout:

```text
/var/lib/darkstar-bootstrap/
├── manifest
└── setups/
    ├── ansible-managed
    ├── dotfiles
    └── nut
```

The manifest currently records bootstrap metadata such as the state format version and initial creation timestamp.

Each setup marker contains information similar to:

```text
module=nut
applied_at=2026-10-13T22:20:18Z
source_commit=a42c9de2b3...
```

The marker is written only after the setup script exits successfully.

Re-applying a setup module updates its marker with the new application time and source commit.

These markers indicate **deployment history**, not full configuration-drift detection. Higher-level tools such as Ansible should be used to assert the desired state of service configuration.

---

## Templates

The `create` command automatically selects the newest locally installed Debian 13 LXC template when `--template` is not specified.

Expected template naming:

```text
local:vztmpl/debian-13-standard_<version>_amd64.tar.zst
```

List locally installed templates:

```bash
pveam list local
```

Refresh the available-template catalog:

```bash
pveam update
```

List available Debian templates:

```bash
pveam available | grep debian
```

Download a template:

```bash
pveam download local debian-13-standard_<version>_amd64.tar.zst
```

Templates may also be downloaded through the Proxmox web interface:

```text
pve-01
└── local
    └── CT Templates
        └── Templates
```

---

## Repository Layout

```text
sbin/
└── bootstrap/
    ├── README.md
    ├── proxmox-lxc
    │
    ├── lib/
    │   ├── debian.sh
    │   ├── proxmox-lxc-common.sh
    │   ├── proxmox-lxc.bash
    │   │
    │   └── commands/
    │       ├── apply.sh
    │       ├── create.sh
    │       ├── list.sh
    │       └── status.sh
    │
    └── setup/
        ├── ansible-managed.sh
        ├── dotfiles.sh
        │
        └── services/
            └── nut.sh
```

Responsibilities:

| File | Purpose |
| --- | --- |
| `proxmox-lxc` | User-facing command dispatcher |
| `lib/proxmox-lxc-common.sh` | Shared Proxmox/container/setup functions |
| `lib/debian.sh` | Mandatory Debian baseline |
| `lib/commands/create.sh` | New-container creation |
| `lib/commands/apply.sh` | Existing-container provisioning |
| `lib/commands/list.sh` | Setup-module discovery |
| `lib/commands/status.sh` | Setup-state and Git-version reporting |
| `lib/proxmox-lxc.bash` | Bash completion |
| `setup/*.sh` | General optional setup modules |
| `setup/services/*.sh` | Service-specific setup modules |

---

## Installing the Command

The repository is currently expected to be cloned on the Proxmox host under:

```text
/opt/darkstar/dotfiles
```

For example:

```bash
sudo mkdir -p /opt/darkstar
sudo git clone https://github.com/raven42/dotfiles.git \
    /opt/darkstar/dotfiles
```

Expose the command through `/usr/local/sbin`:

```bash
sudo ln -s \
    /opt/darkstar/dotfiles/sbin/bootstrap/proxmox-lxc \
    /usr/local/sbin/proxmox-lxc
```

The command resolves the real path behind the symlink, so it can locate its libraries regardless of the current working directory.

Verify:

```bash
proxmox-lxc --help
```

---

## Bash Completion

Bash completion is provided by:

```text
lib/proxmox-lxc.bash
```

Install it with:

```bash
sudo ln -s \
    /opt/darkstar/dotfiles/sbin/bootstrap/lib/proxmox-lxc.bash \
    /etc/bash_completion.d/proxmox-lxc
```

Start a new shell or load it immediately:

```bash
source /etc/bash_completion.d/proxmox-lxc
```

Examples:

```text
proxmox-lxc <TAB>
apply  create  help  list  status
```

VMIDs are discovered dynamically:

```text
proxmox-lxc apply --vmid <TAB>
```

Setup modules are also discovered dynamically:

```text
proxmox-lxc apply --vmid 100 --setup <TAB>
ansible-managed  dotfiles  nut
```

The completion script can also complete Proxmox storage, bridge, and template values where applicable.

---

## Default Container Configuration

New containers default to:

| Setting | Value |
| --- | --- |
| CPU | 1 core |
| Memory | 512 MB |
| Swap | 512 MB |
| Root disk | 8 GB |
| Storage | `local-lvm` |
| Network | DHCP |
| Bridge | `vmbr0` |
| Container | Unprivileged |
| Start at boot | Enabled |
| OS | Debian 13 |

Networking is intentionally configured with DHCP. Long-lived addresses should generally be assigned using DHCP reservations in the network infrastructure rather than configured statically inside the LXC.

---

## Deployment Process

A new deployment follows this flow:

```text
Official Debian LXC Template
            │
            ▼
    proxmox-lxc create
            │
            ▼
       Create LXC
            │
            ▼
       Start LXC
            │
            ▼
     Wait for DHCP
            │
            ▼
 Push Debian bootstrap
      + SSH public key
            │
            ▼
   Apply Debian baseline
            │
            ▼
    Run setup modules
       in requested order
            │
            ▼
   Record setup markers
            │
            ▼
        LXC ready
```

Updating an existing container follows the same baseline/setup process without recreating the LXC or changing its root password.

---

## Recommended Workflow

For a new service:

1. Download or update the Debian LXC template if needed.
2. Create the LXC with `proxmox-lxc create`.
3. Apply the appropriate setup modules.
4. Create a DHCP reservation and internal DNS entry if necessary.
5. Verify SSH access.
6. Check setup state with `proxmox-lxc status`.
7. Configure the application/service through the appropriate infrastructure-management tooling.
8. Take a Proxmox snapshot at useful milestones.

Example for a NUT node:

```bash
proxmox-lxc create \
    --vmid 100 \
    --hostname nut-01.darkstar.net \
    --setup dotfiles \
    --setup ansible-managed \
    --setup nut
```

Later, after changing the NUT setup module:

```bash
proxmox-lxc apply \
    --vmid 100 \
    --setup nut
```

Then:

```bash
proxmox-lxc status --vmid 100
```

---

## Design Notes

The bootstrap layer is intended to handle:

- base operating-system preparation
- administrative access
- common tooling
- installation of role/service prerequisites

It is **not** intended to replace configuration-management tools.

Service configuration, secrets, and desired-state enforcement should generally live in a separate infrastructure repository and be managed by tooling such as Ansible.

The bootstrap scripts should remain:

- simple
- repeatable
- safe to re-run where practical
- free of secrets
- independent of application-specific configuration

The private SSH key must never be committed to this repository or copied into an LXC. Only public SSH keys should be used by the bootstrap tooling.
