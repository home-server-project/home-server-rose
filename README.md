<p align="center">
  <img src="https://raw.githubusercontent.com/home-server-project/.github/main/logo/banner-navy-mid.png" alt="Home Server Project banner">
</p>

# Home Server Rose

[![stable](https://github.com/home-server-project/home-server-rose/actions/workflows/build.yml/badge.svg)](https://github.com/home-server-project/home-server-rose/actions/workflows/build.yml)
[![testing](https://github.com/home-server-project/home-server-rose/actions/workflows/build-testing.yml/badge.svg)](https://github.com/home-server-project/home-server-rose/actions/workflows/build-testing.yml)

> [!CAUTION]
> **This project is in active development. Do not use these images on a production or real home server yet.**
>
> VM testing is welcome. Bare-metal and production-readiness testing will come later.

Home Server Rose is an independent Home Server Project **bootc** server image built on [AlmaLinux OS](https://almalinux.org/) 10 [minimal-plus](build_files/almalinux-10-minimal-plus.yaml), with a focused Home Server tooling and configuration layer added on top.

## Upstream foundation

We chose AlmaLinux deliberately. Its community-driven, long-term-stable Enterprise Linux foundation is a strong fit for the more conservative side of the Home Server Project, where predictable server behavior matters more than chasing the newest base packages.

AlmaLinux provides the kernel, core operating-system packages and Enterprise Linux foundation. Home Server Project adds the bootc image composition, home-server tooling, configuration, health checks and release pipeline used by Rose.

Rose also follows the work in the official [AlmaLinux bootc-images](https://github.com/AlmaLinux/bootc-images) project and uses the same broader bootc ecosystem.

```text
AlmaLinux OS 10
      |
      v
minimal-plus bootc rootfs
      |
      v
Home Server Rose
      |
      +---- Home Server Rose HCI
             + KVM/QEMU/libvirt
             + Cockpit Machines
             + VirtUI Manager
```

Home Server Rose is an independent community project and is not affiliated with or endorsed by the AlmaLinux OS Foundation.

## Other Home Server Project OS

Prefer a Fedora CoreOS / Universal Blue uCore foundation with a **newer LTS kernel**? See [Home Server Gina](https://github.com/home-server-project/home-server-gina).

Rose and Gina follow the same Home Server Project philosophy, but use different upstream foundations:

- **Rose** — AlmaLinux OS 10 / Enterprise Linux foundation
- **Gina** — Fedora CoreOS + Universal Blue uCore LTS foundation

## Images

The repository builds two image variants in parallel.

| Variant | Stable image | Purpose |
|---|---|---|
| Home Server Rose | `ghcr.io/home-server-project/home-server-rose:10` | Full home-server host without virtualization stack |
| Home Server Rose HCI | `ghcr.io/home-server-project/home-server-rose-hci:10` | Same host plus KVM/QEMU/libvirt and VM-management tooling |

### Release channels

| Channel | Moving tag | Source branch | Scheduled rebuild |
|---|---|---|---|
| Stable | `:10` | `main` | Weekly on Saturday |
| Testing | `:testing` | `testing` | Daily |

Testing receives Home Server Rose changes and refreshed AlmaLinux/external-project updates earlier. Stable and testing use the same critical health checks and image-signing process.

## What is included

Rose has a broader built-in home-server layer than Gina, so the main README groups capabilities instead of listing every package individually.

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

## Development status

Current goal: build both signed images, validate them in VMs, then proceed to controlled bare-metal testing.

The repository should not be considered production-ready until that testing is complete.

Architecture and feature decisions are tracked in [`docs/home-server-rose-roadmap.md`](docs/home-server-rose-roadmap.md).

Release health and dependency-update behavior are defined in [`docs/health-and-update-policy.md`](docs/health-and-update-policy.md).

## Updates

AlmaLinux/EPEL/RPM packages follow the current enabled build repositories on every rebuild. mergerfs follows its latest stable upstream EL10 release. UPSide, Superfile and VirtUI Manager are consumed from verified [Home Server Packages](https://github.com/home-server-project/home-server-packages) stable artifacts.

Critical server functionality is tested before publication. In particular, mergerfs must complete a real FUSE mount/read/write/unmount smoke test, and the HCI image must pass its virtualization-management health checks.

Optional utilities may be reported as degraded without blocking an otherwise healthy OS image.

## Image signing and releases

Successful stable builds from `main` publish both moving `:10` tags and matching immutable tags:

```text
10-YYYYMMDD-<git-sha>
```

Successful testing builds from `testing` publish both moving `:testing` tags and matching immutable tags:

```text
testing-YYYYMMDD-<git-sha>
```

Published image digests are signed with Cosign. A GitHub Release is created only for the stable channel after **both** image builds succeed and matching immutable tags are available.

## Issue policy

Open an issue in this repository when the problem is caused by something Home Server Rose adds or integrates.

Examples:

- a Rose build or release workflow fails
- a Home Server Project configuration is wrong
- an added utility is missing or packaged incorrectly
- Rose image signing or trust configuration is broken
- the Rose normal/HCI separation is wrong

If the same problem also happens on the relevant upstream AlmaLinux package, bootc component, Cockpit component or other upstream project, report it to the project that maintains that component.

Kernel and core AlmaLinux package defects remain upstream AlmaLinux issues. Home Server Project can reproduce, document and route those problems, but Rose does not independently maintain the AlmaLinux kernel or core package set.

<details>
<summary><strong>Upstream issue trackers</strong></summary>

- [AlmaLinux Bug Tracker](https://bugs.almalinux.org/)
- [AlmaLinux bootc-images](https://github.com/AlmaLinux/bootc-images/issues)
- [bootc](https://github.com/bootc-dev/bootc/issues)
- [Cockpit](https://github.com/cockpit-project/cockpit/issues)
- [Network UPS Tools](https://github.com/networkupstools/nut/issues)
- [UPSide](https://github.com/deviationist/cockpit-upside/issues)
- [Tailscale](https://github.com/tailscale/tailscale/issues)
- [NetBird](https://github.com/netbirdio/netbird/issues)
- [mergerfs](https://github.com/trapexit/mergerfs/issues)
- [Micro](https://github.com/zyedidia/micro/issues)
- [Superfile](https://github.com/yorukot/superfile/issues)
- [VirtUI Manager](https://github.com/aginies/virtui-manager/issues)

</details>

## Upstream and references

<details>
<summary><strong>Project and upstream links</strong></summary>

- [AlmaLinux OS](https://almalinux.org/)
- [AlmaLinux Wiki](https://wiki.almalinux.org/)
- [AlmaLinux bootc-images](https://github.com/AlmaLinux/bootc-images)
- [bootc](https://github.com/bootc-dev/bootc)
- [Home Server Gina](https://github.com/home-server-project/home-server-gina)
- [Home Server Packages](https://github.com/home-server-project/home-server-packages)
- [Home Server Project](https://github.com/home-server-project)

</details>

See [`UPSTREAM.md`](UPSTREAM.md) for upstream attribution and relationship details.

## License

Apache-2.0. Third-party software included in the images retains its own upstream license.
