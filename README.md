<p align="center">
  <img src="https://raw.githubusercontent.com/home-server-project/.github/main/logo/banner-navy-mid.png" alt="Home Server Project banner">
</p>

# Home Server Rose

[![stable](https://img.shields.io/github/actions/workflow/status/home-server-project/home-server-rose/build.yml?branch=main&label=stable)](https://github.com/home-server-project/home-server-rose/actions/workflows/build.yml)
[![testing](https://img.shields.io/github/actions/workflow/status/home-server-project/home-server-rose/build-testing.yml?branch=testing&label=testing)](https://github.com/home-server-project/home-server-rose/actions/workflows/build-testing.yml)

> [!CAUTION]
> **This project is in active development. Do not use these images on a production or real home server yet.**
>
> VM testing is welcome. Bare-metal and production-readiness testing will come later.

Home Server Rose is an independent Home Server Project **bootc** server image built on [Home Server Base 10](https://github.com/home-server-project/home-server-base-10), with a focused home-server tooling and configuration layer added on top.

## Foundation

Rose uses the following image chain:

```text
AlmaLinux 10
     |
     v
Home Server Base 10
     |
     v
Home Server Rose
     |
     +---- Home Server Rose HCI
            + KVM/QEMU/libvirt
            + Cockpit Machines
            + VirtUI Manager
```

AlmaLinux provides the upstream Enterprise Linux kernel and core operating-system packages. Home Server Base 10 owns the shared AlmaLinux 10 Minimal Plus bootc foundation and generic base behavior. Rose owns the home-server-specific tooling, configuration, health checks and release policy.

Home Server Rose is an independent community project and is not affiliated with or endorsed by the AlmaLinux OS Foundation.

## Other Home Server Project OS

Prefer a Fedora CoreOS / Universal Blue uCore foundation with a **newer LTS kernel**? See [Home Server Gina](https://github.com/home-server-project/home-server-gina).

- **Rose** — Home Server Base 10 / AlmaLinux 10 Enterprise Linux foundation
- **Gina** — Fedora CoreOS + Universal Blue uCore LTS foundation

## Images

| Variant | Stable image | Purpose |
|---|---|---|
| Home Server Rose | `ghcr.io/home-server-project/home-server-rose:10` | Full home-server host without virtualization stack |
| Home Server Rose HCI | `ghcr.io/home-server-project/home-server-rose-hci:10` | Same host plus KVM/QEMU/libvirt and VM-management tooling |

### Release channels

| Channel | Moving tag | Source branch | Schedule |
|---|---|---|---|
| Stable | `:10` | `main` | Friday 15:30 UTC |
| Testing | `:testing` | `testing` | Daily 14:30 UTC |

Testing is the daily canary for the current Home Server Base and Rose package set. Stable performs its own complete validation before publication and does not depend on the status of a particular Testing workflow run.

## What is included

| Area | Included |
|---|---|
| Containers | Podman, systemd Quadlets, Toolbx |
| Administration | Cockpit host integration, Micro, Superfile, btop, fastfetch, tmux, jq, rsync, pv |
| Storage / NAS | Btrfs tools, mergerfs, NFS, Samba, rclone, duperemove, SMART/NVMe/drive utilities |
| Networking | NetworkManager, firewalld, Tailscale, NetBird, WireGuard tools, common network diagnostics |
| UPS / power | NUT, UPSide, PowerTOP |
| Hardware | Intel/AMD firmware and GPU support, fwupd, sensors, common USB/PCI utilities |
| HCI only | KVM/QEMU, libvirt, Cockpit Machines, `virsh`, `virt-install`, VirtUI Manager, UEFI/TPM VM support |

Third-party package details are maintained in [Home Server Packages](https://github.com/home-server-project/home-server-packages).

Both variants use the same general Home Server feature layer. HCI adds only the virtualization stack and tools that directly manage virtual machines.

Applications such as Jellyfin, Vaultwarden, databases, media automation, monitoring stacks and reverse proxies belong in Podman Quadlets rather than being baked into the host image.

The project deliberately does **not** include Docker/Moby, ZFS or NVIDIA support in the current scope.

## Administrative access

Home Server Rose follows the passwordless administrator pattern used by Fedora CoreOS/uCore. Users in the standard `wheel` group can use `sudo` without an additional password prompt.

No passwords or machine-specific credentials are baked into the image.

The system uses a fixed **4 GiB zram swap device** and does not require a disk swap partition.

## Updates and health

Home Server Base 10 supplies the AlmaLinux 10 Minimal Plus parent and shared base behavior. Rose installs its additional AlmaLinux/EPEL packages and Home Server tooling during each rebuild.

mergerfs follows its latest stable upstream EL10 release. UPSide, Superfile and VirtUI Manager are consumed from verified [Home Server Packages](https://github.com/home-server-project/home-server-packages) stable artifacts.

Critical server functionality is tested before publication. In particular:

- bootc container lint must pass
- Rose identity and Home Server Base provenance must validate
- mergerfs must complete a real FUSE mount/read/write/unmount smoke test
- the standard image must remain free of the HCI virtualization stack
- the HCI image must pass its virtualization-management health checks
- published image digests must pass Cosign signing and verification

Optional utilities may be reported as degraded without blocking an otherwise healthy OS image.

The detailed release-health contract is documented in [`docs/health-and-update-policy.md`](docs/health-and-update-policy.md).

## Image signing and releases

Successful stable builds publish the moving `:10` tag and an immutable tag:

```text
10-YYYYMMDD-<git-sha>
```

Successful testing builds publish the moving `:testing` tag and an immutable tag:

```text
testing-YYYYMMDD-<git-sha>
```

Published image digests are signed with Cosign.

Testing builds do not create GitHub Releases. A stable GitHub Release is created only after both Home Server Rose and Home Server Rose HCI pass the stable release-health contract.

GHCR immutable image history is retained separately from GitHub Releases. Testing and stable image cleanup keeps at least seven recent tagged builds and removes matching immutable image versions older than 45 days while preserving the moving channel tags.

## Issue policy

Open an issue in this repository when the problem is caused by something Home Server Rose adds or integrates, including:

- Rose build or release workflow failures
- Home Server Project configuration problems
- missing or incorrectly integrated Rose utilities
- image-signing or trust configuration failures
- incorrect normal/HCI separation

Problems reproducible in the upstream AlmaLinux package, bootc component, Cockpit component or another upstream project should be reported to the project that maintains that component.

## Upstream and references

- [Home Server Base 10](https://github.com/home-server-project/home-server-base-10)
- [AlmaLinux OS](https://almalinux.org/)
- [AlmaLinux bootc-images](https://github.com/AlmaLinux/bootc-images)
- [bootc](https://github.com/bootc-dev/bootc)
- [Home Server Gina](https://github.com/home-server-project/home-server-gina)
- [Home Server Packages](https://github.com/home-server-project/home-server-packages)
- [Home Server Project](https://github.com/home-server-project)

See [`UPSTREAM.md`](UPSTREAM.md) for detailed upstream attribution and relationship information.

## License

Apache-2.0. Third-party software included in the images retains its own upstream license.
