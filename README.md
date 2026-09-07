# Home Server Alma

[![stable](https://github.com/home-server-project/home-server-alma/actions/workflows/build.yml/badge.svg)](https://github.com/home-server-project/home-server-alma/actions/workflows/build.yml)
[![testing](https://github.com/home-server-project/home-server-alma/actions/workflows/build-testing.yml/badge.svg)](https://github.com/home-server-project/home-server-alma/actions/workflows/build-testing.yml)

> [!CAUTION]
> **This project is in active development. Do not use these images on a production or real home server yet.**
>
> VM testing is welcome. Bare-metal and production-readiness testing will come later.

Home Server Alma is an opinionated AlmaLinux 10 **bootc** server image built from AlmaLinux's
**minimal-plus** content tier.

The repository builds two image variants in parallel:

- `home-server-alma`
- `home-server-alma-hci`

The stable channel is rebuilt weekly on Saturday:

- `ghcr.io/home-server-project/home-server-alma:10`
- `ghcr.io/home-server-project/home-server-alma-hci:10`

The testing channel is rebuilt daily and follows the `testing` branch:

- `ghcr.io/home-server-project/home-server-alma:testing`
- `ghcr.io/home-server-project/home-server-alma-hci:testing`

The testing channel is intended for earlier exposure to current Home Server Alma changes and refreshed
upstream AlmaLinux and external-project updates. Stable and testing use the same critical health checks
and image-signing process.

Both images contain the same full Home Server feature set: Podman + Quadlets, Cockpit host
integration, storage/NAS tools, NUT + UPSide, Tailscale, NetBird, WireGuard tools, Intel/AMD
hardware, and practical terminal administration tools.

`home-server-alma-hci` adds only the virtualization stack:

- KVM/QEMU/libvirt
- Cockpit Machines
- `virsh`
- `virt-install`
- VirtUI Manager
- direct VM firmware/TPM/console dependencies

The project deliberately does **not** include Docker/Moby, ZFS or NVIDIA support in the current
scope. Applications are intended to run as Podman Quadlets.

The system uses a fixed **4 GiB zram swap device** and does not require a disk swap partition.

## Administrative access

Home Server Alma follows the passwordless administrator pattern used by Fedora CoreOS/uCore. Users
in AlmaLinux's standard `wheel` group can use `sudo` without an additional password prompt. This is
intended for trusted administrator accounts on an appliance-style home server.

## Development status

Current goal: build both signed images, validate them in VMs, then proceed to controlled bare-metal
testing. The repository should not be considered production-ready until that testing is complete.

Architecture and feature decisions are tracked in
[`docs/home-server-alma-roadmap.md`](docs/home-server-alma-roadmap.md).

Release health and dependency-update behavior are defined in
[`docs/health-and-update-policy.md`](docs/health-and-update-policy.md).

## Update model

Alma/EPEL/RPM packages follow the current enabled repositories on every rebuild. External projects
such as mergerfs, UPSide, Superfile and VirtUI Manager follow their latest stable upstream release by
default. Version pins are emergency regression overrides, not routine maintenance.

Critical server functionality is tested before publication. In particular, mergerfs must complete a
real FUSE mount/read/write/unmount smoke test, and the HCI image must pass its virtualization-management
health checks. Optional utilities may be reported as degraded without blocking an otherwise healthy
OS image.

## Images and releases

Successful stable builds from `main` publish both moving `:10` tags and matching immutable tags in the form:

```text
10-YYYYMMDD-<git-sha>
```

Successful testing builds from `testing` publish both moving `:testing` tags and matching immutable tags in the form:

```text
testing-YYYYMMDD-<git-sha>
```

Published image digests are signed with Cosign. A GitHub Release is created only for the stable
channel after **both** image builds succeed and matching immutable tags are available. Daily testing
builds do not create GitHub Releases.

## License

Apache-2.0. Third-party software included in the images retains its own upstream license.
