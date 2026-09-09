#!/usr/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT}/build_files/software.env"

output="${1:-/tmp/home-server-rose-external.env}"

curl_args=(-fsSL -H 'Accept: application/vnd.github+json')
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    curl_args+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

if [[ -n "${MERGERFS_PIN}" ]]; then
    mergerfs_endpoint="${MERGERFS_RELEASE_API}/tags/${MERGERFS_PIN}"
else
    mergerfs_endpoint="${MERGERFS_RELEASE_API}/latest"
fi

mergerfs_json="$(curl "${curl_args[@]}" "${mergerfs_endpoint}")"
mergerfs_tag="$(jq -er '.tag_name' <<<"${mergerfs_json}")"
mergerfs_asset="$(
    jq -er '
        .assets[]
        | select(.name | test("^mergerfs-.*[.]el10[.]x86_64[.]rpm$"))
        | [.browser_download_url, .digest]
        | @tsv
    ' <<<"${mergerfs_json}" | head -n 1
)"

IFS=$'\t' read -r mergerfs_url mergerfs_digest <<<"${mergerfs_asset}"
if [[ ! "${mergerfs_digest}" =~ ^sha256:[0-9a-f]{64}$ ]]; then
    echo "ERROR: mergerfs release ${mergerfs_tag} has no usable upstream SHA-256 digest." >&2
    exit 1
fi
mergerfs_sha256="${mergerfs_digest#sha256:}"

cat > "${output}" <<EOF_OUT
mergerfs_tag=${mergerfs_tag}
mergerfs_url=${mergerfs_url}
mergerfs_sha256=${mergerfs_sha256}
EOF_OUT

cat "${output}"
