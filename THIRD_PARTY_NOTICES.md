# Third-party notices

Home Server Rose is licensed under Apache-2.0. Software installed into the image retains its own
upstream license.

## Universal Blue uCore

The Realtek USB Ethernet udev rule in
`system_files/etc/udev/rules.d/50-usb-realtek-net.rules` is adapted from the Universal Blue uCore
project:

https://github.com/ublue-os/ucore

uCore is distributed under Apache-2.0. The rule has been carried over because it is useful generic
home-server hardware enablement; comments were adjusted for this project.

## Home Server Packages

UPSide, Superfile, and VirtUI Manager are consumed as verified RPM artifacts from:

https://github.com/home-server-project/home-server-packages

That repository owns their upstream source tracking, package builds, validation, licenses, and
published package artifacts. Home Server Rose resolves the stable package artifacts to exact digests
for each image build. VirtUI Manager is included only in Home Server Rose HCI.

Upstream projects:

- UPSide: https://github.com/deviationist/cockpit-upside
- Superfile: https://github.com/yorukot/superfile
- VirtUI Manager: https://github.com/aginies/virtui-manager

## mergerfs

https://github.com/trapexit/mergerfs

The image follows the latest stable upstream EL10 RPM by default and verifies the upstream-published
SHA-256 digest. A version pin is used only as a temporary regression workaround.
