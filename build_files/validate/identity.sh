#!/usr/bin/bash
set -euo pipefail

pass() { printf 'PASS  %s\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

OS_RELEASE_USR=/usr/lib/os-release
OS_RELEASE_ETC=/etc/os-release
[[ -r "${OS_RELEASE_USR}" ]] || fail "${OS_RELEASE_USR} is missing"

# shellcheck disable=SC1090
source "${OS_RELEASE_USR}"

[[ "${ID:-}" == "home-server-rose" ]] || fail "ID=${ID:-unset}; expected home-server-rose"
[[ "${NAME:-}" == "Home Server Rose" ]] || fail "NAME=${NAME:-unset}; expected Home Server Rose"
[[ "${VERSION_ID%%.*}" == "10" ]] || fail "VERSION_ID=${VERSION_ID:-unset}; expected EL10 major version"
[[ "${PLATFORM_ID:-}" == "platform:el10" ]] || fail "PLATFORM_ID=${PLATFORM_ID:-unset}; expected platform:el10"

for family in almalinux rhel centos fedora; do
    [[ " ${ID_LIKE:-} " == *" ${family} "* ]] || fail "ID_LIKE=${ID_LIKE:-unset}; missing ${family}"
done

case "${VARIANT_ID:-}" in
    home-server-rose)
        expected_pretty="Home Server Rose 10"
        expected_variant="Home Server Rose"
        ;;
    home-server-rose-hci)
        expected_pretty="Home Server Rose HCI 10"
        expected_variant="Home Server Rose HCI"
        ;;
    *)
        fail "VARIANT_ID=${VARIANT_ID:-unset}; expected a Home Server Rose variant"
        ;;
esac

[[ "${PRETTY_NAME:-}" == "${expected_pretty}" ]] || fail "PRETTY_NAME=${PRETTY_NAME:-unset}; expected ${expected_pretty}"
[[ "${VARIANT:-}" == "${expected_variant}" ]] || fail "VARIANT=${VARIANT:-unset}; expected ${expected_variant}"
[[ "${IMAGE_ID:-}" == "${VARIANT_ID}" ]] || fail "IMAGE_ID=${IMAGE_ID:-unset}; expected ${VARIANT_ID}"
[[ "${IMAGE_VERSION:-}" == "10" ]] || fail "IMAGE_VERSION=${IMAGE_VERSION:-unset}; expected 10"
[[ "${VENDOR_NAME:-}" == "Home Server Project" ]] || fail "VENDOR_NAME=${VENDOR_NAME:-unset}"
[[ "${HOME_URL:-}" == "https://github.com/home-server-project/home-server-rose" ]] || fail "HOME_URL=${HOME_URL:-unset}"
[[ "${SUPPORT_URL:-}" == "https://github.com/home-server-project/home-server-rose/issues" ]] || fail "SUPPORT_URL=${SUPPORT_URL:-unset}"
[[ "${BUG_REPORT_URL:-}" == "https://github.com/home-server-project/home-server-rose/issues" ]] || fail "BUG_REPORT_URL=${BUG_REPORT_URL:-unset}"
[[ "${CPE_NAME:-}" == "cpe:/o:home-server-project:home-server-rose:10" ]] || fail "CPE_NAME=${CPE_NAME:-unset}"

[[ "${HOME_SERVER_ROSE_BASE_ID:-}" == "almalinux" ]] || fail "base ID metadata is not almalinux"
[[ "${HOME_SERVER_ROSE_BASE_VERSION_ID%%.*}" == "10" ]] || fail "base VERSION_ID metadata is not AlmaLinux 10"
[[ "${HOME_SERVER_ROSE_BASE_PLATFORM_ID:-}" == "platform:el10" ]] || fail "base PLATFORM_ID metadata is not platform:el10"
[[ "${HOME_SERVER_ROSE_BASE_CPE_NAME:-}" == cpe:/o:almalinux:* ]] || fail "base CPE metadata does not identify AlmaLinux"
[[ "${HOME_SERVER_ROSE_BASE_PROFILE:-}" == "almalinux-10-minimal-plus" ]] || fail "base profile metadata is incorrect"

for key in ALMALINUX_MANTISBT_PROJECT ALMALINUX_MANTISBT_PROJECT_VERSION REDHAT_SUPPORT_PRODUCT REDHAT_SUPPORT_PRODUCT_VERSION SUPPORT_END LOGO; do
    if grep -q "^${key}=" "${OS_RELEASE_USR}"; then
        fail "upstream product field ${key} remains in Rose os-release"
    fi
done

if [[ -e "${OS_RELEASE_ETC}" ]] && ! [[ "${OS_RELEASE_ETC}" -ef "${OS_RELEASE_USR}" ]]; then
    for key in ID NAME PRETTY_NAME VARIANT VARIANT_ID IMAGE_ID IMAGE_VERSION VENDOR_NAME CPE_NAME HOME_SERVER_ROSE_BASE_ID; do
        usr_value="$(grep -E "^${key}=" "${OS_RELEASE_USR}" | head -n1 || true)"
        etc_value="$(grep -E "^${key}=" "${OS_RELEASE_ETC}" | head -n1 || true)"
        [[ "${usr_value}" == "${etc_value}" ]] || fail "${key} differs between /usr/lib/os-release and /etc/os-release"
    done
fi

for legacy_path in \
    /usr/libexec/home-server-alma \
    /usr/share/home-server-alma \
    /usr/share/doc/home-server-alma \
    /etc/sudoers.d/90-home-server-alma-passwordless-wheel \
    /usr/lib/tmpfiles.d/home-server-alma-resolved.conf \
    /usr/lib/systemd/system/home-server-alma-update.service \
    /usr/lib/systemd/system/home-server-alma-update.timer \
    /usr/lib/sysusers.d/home-server-alma-libvirt-workarounds.conf; do
    [[ ! -e "${legacy_path}" ]] || fail "legacy Home Server Alma path remains: ${legacy_path}"
done

pass "Home Server Rose identity and AlmaLinux 10 base metadata"
printf 'ROSE IDENTITY: PASS\n'
