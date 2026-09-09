# Image Health and Update Policy

This document defines what may block a Home Server Rose image release and how external software is updated.

## Update sources

AlmaLinux and EPEL packages follow the current enabled build repositories on every rebuild.

mergerfs follows the latest stable upstream GitHub release and its EL10 x86_64 RPM. Rose verifies the SHA-256 digest published with the selected release asset before installation. `build_files/software.env` keeps an empty mergerfs emergency pin that is used only after a demonstrated regression.

UPSide, Superfile, and VirtUI Manager are not built from upstream source in this repository. They are consumed from the verified `:stable` artifacts published by [Home Server Packages](https://github.com/home-server-project/home-server-packages).

Each Rose image build resolves those moving stable package artifacts to exact immutable digests before composition. Home Server Packages owns their upstream release tracking, exact source commits, package recipes, dependency locks, license handling, and Fedora/AlmaLinux package validation.

UPSide and Superfile are required by both Rose variants. VirtUI Manager is required only by Home Server Rose HCI. Failure to resolve or install one of the required central package artifacts blocks the affected image build.

## Critical health contract

A critical failure blocks the affected image before GHCR push, signing or GitHub Release creation.

Both images require:

- bootc container lint
- valid image trust configuration and readable SELinux policy
- Podman and Quadlet integration
- NetworkManager, firewalld and SSH tooling
- Cockpit host bridge/pages required by the base design
- fixed 4 GiB zram configuration
- Btrfs userspace tools with a disposable filesystem smoke test
- NFS and Samba core tooling
- Intel compute runtime plus Intel/AMD GPU firmware needed by the host device layer
- mergerfs package plus a real FUSE mount/read/write/unmount smoke test
- UPSide RPM plus its Cockpit manifest
- Superfile RPM plus the `spf` command

GPU media acceleration follows a container-first model. The host supplies kernel GPU drivers, firmware and `/dev/dri`; application containers such as Jellyfin supply their own VA-API/Quick Sync or Mesa userspace stack. CI therefore does not require host `libva`, `intel-media-driver` or Mesa VA-API packages. Real media acceleration remains a hardware acceptance test using actual containers.

The mergerfs functional test is intentionally strict because a broken mergerfs layer can make application storage unavailable to services such as Jellyfin.

HCI additionally requires:

- cockpit-machines
- libvirt client and KVM daemon packages
- QEMU/KVM
- virt-install
- swtpm and VM firmware
- VirtUI Manager RPM and CLI entry points

VirtUI Manager package internals and its private Python dependency set are validated by Home Server Packages. Rose validates that the package is installed and that its user-facing commands are present as part of the HCI integration contract.

CI does not claim that nested KVM itself works merely because GitHub Actions passes. Real VM creation/boot, bridge networking, UEFI and TPM remain VM/bare-metal acceptance tests.

## Optional/degraded health

The following capabilities are intended to be present on both images but do not justify blocking an otherwise healthy OS/security rebuild by themselves:

- NUT / UPS utilities
- Tailscale
- NetBird
- WireGuard tooling
- fwupd and hardware diagnostic tools
- PowerTOP
- btop
- Micro
- fastfetch
- tmux
- jq/rsync/pv and similar administration utilities
- rclone/duperemove and other non-runtime storage helpers

Optional failures are reported as `WARN` / `OPTIONAL HEALTH: DEGRADED` in the GitHub Actions summary.

Degraded does not mean ignored. It means the image remains operational and may still receive important OS updates while the optional regression is investigated.

## Release gate

The pipeline is:

```text
resolve mergerfs + exact package artifact digests
        |
        v
build both images in parallel
        |
        v
critical common health
        |
        +---- base: confirm HCI stack and VirtUI Manager absent
        |
        +---- HCI: critical virtualization health
        |
        v
optional health report
        |
        v
push -> sign -> verify
        |
        v
GitHub Release only after both matrix images succeed
```

A failed critical check means no new moving `:10` image for that target and therefore no paired GitHub Release.
