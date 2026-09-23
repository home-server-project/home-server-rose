# Image Health and Update Policy

This document defines what may block a Home Server Rose image release and how external software is updated.

## Update sources

Home Server Rose consumes the moving Home Server Base 10 channels: `:stable` for the normal x86-64-v3 baseline and `:stable-v2` for the compatibility x86-64-v2 baseline. CI resolves the selected parent to an exact digest and verifies its Home Server Project Cosign signature before composition. Home Server Base supplies the AlmaLinux 10 Minimal Plus foundation and enabled base repositories; Rose then installs its additional AlmaLinux/EPEL packages during the rebuild.

Normal x86-64-v3 Rose builds follow the latest stable upstream mergerfs GitHub release and its EL10 x86_64 RPM, verifying the upstream-published SHA-256 digest before installation. x86-64-v2 builds consume the separately built, validated and digest-resolved `mergerfs:stable-v2` artifact from Home Server Packages. `build_files/software.env` keeps the upstream mergerfs emergency pin only for the normal upstream path.

UPSide and VirtUI Manager are not built from upstream source in this repository. They are consumed from the verified `:stable` artifacts published by [Home Server Packages](https://github.com/home-server-project/home-server-packages).

Each Rose image build resolves those moving stable package artifacts to exact immutable digests before composition. Home Server Packages owns their upstream release tracking, exact source commits, package recipes, dependency locks, license handling, and Fedora/AlmaLinux package validation.

uBlue Brew is consumed from `ghcr.io/ublue-os/brew:latest`. Each build resolves that moving tag to the current immutable digest and verifies the uBlue signature before composition. Homebrew itself remains mutable under `/home/linuxbrew/.linuxbrew` and updates normally with `brew update`.

UPSide and the uBlue Brew integration are required by both Rose product variants at both CPU baselines. mergerfs is required through the baseline-specific source described above. VirtUI Manager is required only by Home Server Rose HCI. Failure to resolve or install one of these required inputs blocks the affected image build.

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
- uBlue Brew bootstrap payload, service units, shell integration, and Homebrew Linux prerequisites

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
- WireGuard tooling
- fwupd and hardware diagnostic tools
- PowerTOP
- tmux
- jq/rsync/pv and similar administration utilities
- rclone/duperemove and other non-runtime storage helpers

Optional failures are reported as `WARN` / `OPTIONAL HEALTH: DEGRADED` in the GitHub Actions summary.

Degraded does not mean ignored. It means the image remains operational and may still receive important OS updates while the optional regression is investigated.

## Release gate

The pipeline is:

```text
resolve + verify exact Home Server Base digest
        |
        v
resolve mergerfs + exact package/Brew image digests
        |
        v
build both products at both CPU baselines in parallel
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
GitHub Release only after all four matrix builds succeed
```

A failed critical check means no new moving stable image for that product/baseline target (`:10` or `:10-v2`) and therefore no GitHub Release for that source revision.
