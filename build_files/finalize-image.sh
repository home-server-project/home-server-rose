#!/usr/bin/bash
set -ouex pipefail

: "${IMAGE_REPOSITORY:?IMAGE_REPOSITORY must be set}"
: "${IMAGE_PRETTY_NAME:?IMAGE_PRETTY_NAME must be set}"
: "${IMAGE_VARIANT:?IMAGE_VARIANT must be set}"
: "${IMAGE_VARIANT_ID:?IMAGE_VARIANT_ID must be set}"

/ctx/build_files/install-image-trust.sh "${IMAGE_REPOSITORY}"

OS_RELEASE_USR=/usr/lib/os-release
OS_RELEASE_ETC=/etc/os-release

[[ -r "${OS_RELEASE_USR}" ]] || { echo "ERROR: ${OS_RELEASE_USR} is missing." >&2; exit 1; }

# Capture the real upstream foundation before applying the downstream Rose identity.
# These values remain available as Home Server Project extension fields after branding.
# shellcheck disable=SC1090
source "${OS_RELEASE_USR}"
BASE_ID="${ID:-}"
BASE_PRETTY_NAME="${PRETTY_NAME:-}"
BASE_VERSION_ID="${VERSION_ID:-}"
BASE_PLATFORM_ID="${PLATFORM_ID:-}"
BASE_CPE_NAME="${CPE_NAME:-}"

[[ "${BASE_ID}" == "almalinux" ]] || {
    echo "ERROR: expected AlmaLinux upstream ID before Rose branding, got '${BASE_ID}'." >&2
    exit 1
}
[[ "${BASE_VERSION_ID%%.*}" == "10" ]] || {
    echo "ERROR: expected AlmaLinux major version 10, got '${BASE_VERSION_ID}'." >&2
    exit 1
}
[[ "${BASE_PLATFORM_ID}" == "platform:el10" ]] || {
    echo "ERROR: expected platform:el10, got '${BASE_PLATFORM_ID}'." >&2
    exit 1
}

OS_RELEASE_FILES=("${OS_RELEASE_USR}")
if [[ -e "${OS_RELEASE_ETC}" ]] && ! [[ "${OS_RELEASE_ETC}" -ef "${OS_RELEASE_USR}" ]]; then
    OS_RELEASE_FILES+=("${OS_RELEASE_ETC}")
fi

osr_set() {
    local key="$1" value="$2" file
    for file in "${OS_RELEASE_FILES[@]}"; do
        sed -i "/^${key}=/d" "${file}"
        printf '%s="%s"\n' "${key}" "${value}" >> "${file}"
    done
}

osr_unset() {
    local key="$1" file
    for file in "${OS_RELEASE_FILES[@]}"; do
        sed -i "/^${key}=/d" "${file}"
    done
}

# Home Server Rose is the resulting image identity. AlmaLinux remains the
# upstream package/kernel foundation and EL10 compatibility family.
osr_set NAME "Home Server Rose"
osr_set PRETTY_NAME "${IMAGE_PRETTY_NAME}"
osr_set ID "home-server-rose"
osr_set ID_LIKE "almalinux rhel centos fedora"
osr_set VERSION "${BASE_VERSION_ID}"
osr_set VARIANT "${IMAGE_VARIANT}"
osr_set VARIANT_ID "${IMAGE_VARIANT_ID}"
osr_set IMAGE_ID "${IMAGE_VARIANT_ID}"
osr_set IMAGE_VERSION "10"
osr_set HOME_URL "https://github.com/home-server-project/home-server-rose"
osr_set DOCUMENTATION_URL "https://github.com/home-server-project/home-server-rose/tree/main/docs"
osr_set SUPPORT_URL "https://github.com/home-server-project/home-server-rose/issues"
osr_set BUG_REPORT_URL "https://github.com/home-server-project/home-server-rose/issues"
osr_set VENDOR_NAME "Home Server Project"
osr_set VENDOR_URL "https://github.com/home-server-project"
osr_set CPE_NAME "cpe:/o:home-server-project:home-server-rose:10"

# Preserve the exact upstream identity as namespaced metadata instead of
# presenting the combined Rose image itself as AlmaLinux OS.
osr_set HOME_SERVER_ROSE_BASE_ID "${BASE_ID}"
osr_set HOME_SERVER_ROSE_BASE_PRETTY_NAME "${BASE_PRETTY_NAME}"
osr_set HOME_SERVER_ROSE_BASE_VERSION_ID "${BASE_VERSION_ID}"
osr_set HOME_SERVER_ROSE_BASE_PLATFORM_ID "${BASE_PLATFORM_ID}"
osr_set HOME_SERVER_ROSE_BASE_CPE_NAME "${BASE_CPE_NAME}"
osr_set HOME_SERVER_ROSE_BASE_PROFILE "almalinux-10-minimal-plus"

# Upstream support/vendor extension fields describe AlmaLinux itself, not this
# downstream combined image. The upstream values above retain provenance.
for key in \
    ALMALINUX_MANTISBT_PROJECT \
    ALMALINUX_MANTISBT_PROJECT_VERSION \
    REDHAT_SUPPORT_PRODUCT \
    REDHAT_SUPPORT_PRODUCT_VERSION \
    SUPPORT_END \
    LOGO; do
    osr_unset "${key}"
done

chmod 0644 "${OS_RELEASE_FILES[@]}"

# External package repositories are build-time inputs only. Keep their files for
# provenance and future image composition, but do not leave them enabled on the
# deployed immutable host.
for repo_file in \
    /etc/yum.repos.d/epel*.repo \
    /etc/yum.repos.d/tailscale.repo \
    /etc/yum.repos.d/netbird.repo; do
    [[ -e "${repo_file}" ]] || continue
    sed -Ei 's/^[[:space:]]*enabled[[:space:]]*=[[:space:]]*1[[:space:]]*$/enabled=0/' "${repo_file}"
done

if dnf repolist --enabled | grep -Eiq 'epel|tailscale|netbird'; then
    echo "ERROR: an external package repository remains enabled in the final image."
    dnf repolist --enabled
    exit 1
fi

# bootc images must not carry build-time package-manager/runtime state in /var.
# Keep /var/tmp in the image skeleton because early services such as
# systemd-resolved can require PrivateTmp before systemd-tmpfiles-setup runs.
dnf clean all
rm -rf /var
install -d -m0755 /var
install -d -m1777 /var/tmp
test "$(stat -c '%a %U %G' /var/tmp)" = "1777 root root"

jq empty /etc/containers/policy.json
test -f /usr/lib/pki/containers/home-server-project.pub
test -f /etc/containers/registries.d/ghcr.io-home-server-project.yaml
grep -Fq "${IMAGE_REPOSITORY}:" /etc/containers/registries.d/ghcr.io-home-server-project.yaml
grep -Fq "use-sigstore-attachments: true" /etc/containers/registries.d/ghcr.io-home-server-project.yaml
