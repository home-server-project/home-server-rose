#!/usr/bin/bash
set -u

degraded=0
pass() { printf 'PASS  %s\n' "$*"; }
warn() { printf 'WARN  %s\n' "$*"; degraded=1; }

check_cmd() {
    local cmd="$1"
    if command -v "${cmd}" >/dev/null 2>&1; then
        pass "${cmd}"
    else
        warn "${cmd} missing"
    fi
}

for cmd in upsc nut-scanner tailscale netbird fwupdmgr smartctl sensors nvme \
           lsusb lspci ethtool powertop btop micro nano vim openssl lsof file unzip \
           tmux jq rsync pv tcpdump dig traceroute nc iperf3 rclone; do
    check_cmd "${cmd}"
done

if [[ -d /usr/share/home-server-rose/build-health ]]; then
    while IFS= read -r marker; do
        [[ -n "${marker}" ]] || continue
        warn "build marker: $(basename "${marker}")"
    done < <(find /usr/share/home-server-rose/build-health -maxdepth 1 -type f -name '*.failed' -print | sort)
fi

if (( degraded )); then
    printf 'OPTIONAL HEALTH: DEGRADED\n'
else
    printf 'OPTIONAL HEALTH: PASS\n'
fi

# Optional health never blocks publishing by itself.
exit 0
