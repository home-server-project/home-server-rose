ARG HOME_SERVER_BASE_IMAGE=ghcr.io/home-server-project/home-server-base-10:stable
ARG UPSIDE_PACKAGE_IMAGE=ghcr.io/home-server-project/cockpit-upside:stable
ARG SUPERFILE_PACKAGE_IMAGE=ghcr.io/home-server-project/superfile:stable
ARG VIRTUI_MANAGER_PACKAGE_IMAGE=ghcr.io/home-server-project/virtui-manager:stable
ARG HOME_SERVER_ROSE_REPOSITORY=ghcr.io/home-server-project/home-server-rose
ARG HOME_SERVER_ROSE_HCI_REPOSITORY=ghcr.io/home-server-project/home-server-rose-hci

# -----------------------------------------------------------------------------
# Verified shared third-party package artifacts
# -----------------------------------------------------------------------------
FROM ${UPSIDE_PACKAGE_IMAGE} AS upside-package
FROM ${SUPERFILE_PACKAGE_IMAGE} AS superfile-package

# -----------------------------------------------------------------------------
# Build context exposed to bind mounts
# -----------------------------------------------------------------------------
FROM scratch AS ctx
COPY build_files /build_files
COPY system_files /system_files
COPY quadlets /quadlets
COPY docs /docs
COPY cosign.pub /cosign.pub

# -----------------------------------------------------------------------------
# Shared full Home Server feature layer
# -----------------------------------------------------------------------------
FROM ${HOME_SERVER_BASE_IMAGE} AS home-server-common
ARG MERGERFS_URL
ARG MERGERFS_SHA256

LABEL containers.bootc=1 \
      ostree.bootable=1 \
      org.opencontainers.image.vendor="Home Server Project" \
      io.home-server-project.base-profile="almalinux-10-minimal-plus" \
      io.home-server-project.status="development"

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=bind,from=upside-package,source=/rpms,target=/upside-rpm \
    --mount=type=bind,from=superfile-package,source=/rpms,target=/superfile-rpm \
    --mount=type=tmpfs,dst=/run \
    --mount=type=tmpfs,dst=/tmp \
    MERGERFS_URL="${MERGERFS_URL}" \
    MERGERFS_SHA256="${MERGERFS_SHA256}" \
    /ctx/build_files/build-common.sh

# This shared stage still contains transient package-manager/runtime state that is
# cleaned by finalize-image.sh. Check structural bootc validity here, and reserve
# fatal warnings for the completed variants after finalization.
RUN bootc container lint
STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]

# -----------------------------------------------------------------------------
# Standard Home Server Rose image
# -----------------------------------------------------------------------------
FROM home-server-common AS home-server-rose
ARG HOME_SERVER_ROSE_REPOSITORY

LABEL org.opencontainers.image.title="Home Server Rose" \
      org.opencontainers.image.description="Home Server Base 10-derived bootc home-server image" \
      org.opencontainers.image.source="https://github.com/home-server-project/home-server-rose" \
      io.home-server-project.variant="home-server-rose"

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    IMAGE_REPOSITORY="${HOME_SERVER_ROSE_REPOSITORY}" \
    IMAGE_PRETTY_NAME="Home Server Rose 10" \
    IMAGE_VARIANT="Home Server Rose" \
    IMAGE_VARIANT_ID="home-server-rose" \
    /ctx/build_files/finalize-image.sh

RUN bootc container lint --fatal-warnings

# -----------------------------------------------------------------------------
# HCI-only verified package artifact
# -----------------------------------------------------------------------------
FROM ${VIRTUI_MANAGER_PACKAGE_IMAGE} AS virtui-manager-package

# -----------------------------------------------------------------------------
# HCI: exact same common layer plus virtualization
# -----------------------------------------------------------------------------
FROM home-server-common AS home-server-rose-hci
ARG HOME_SERVER_ROSE_HCI_REPOSITORY

LABEL org.opencontainers.image.title="Home Server Rose HCI" \
      org.opencontainers.image.description="Home Server Rose plus KVM/QEMU/libvirt virtualization" \
      org.opencontainers.image.source="https://github.com/home-server-project/home-server-rose" \
      io.home-server-project.variant="home-server-rose-hci"

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=bind,from=virtui-manager-package,source=/rpms,target=/virtui-manager-rpm \
    --mount=type=tmpfs,dst=/run \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build_files/build-hci.sh

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    IMAGE_REPOSITORY="${HOME_SERVER_ROSE_HCI_REPOSITORY}" \
    IMAGE_PRETTY_NAME="Home Server Rose HCI 10" \
    IMAGE_VARIANT="Home Server Rose HCI" \
    IMAGE_VARIANT_ID="home-server-rose-hci" \
    /ctx/build_files/finalize-image.sh

RUN bootc container lint --fatal-warnings
