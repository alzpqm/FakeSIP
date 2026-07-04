#!/usr/bin/env bash
set -u

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
WORK_DIR="${WORK_DIR:-/tmp/fakesip-smoke}"
LOG="$WORK_DIR/smoke.log"

mkdir -p "$WORK_DIR"
: >"$LOG"

run() {
    echo "\$ $*" | tee -a "$LOG"
    "$@" 2>&1 | tee -a "$LOG"
    local rc=${PIPESTATUS[0]}
    echo "[exit $rc]" | tee -a "$LOG"
    return "$rc"
}

section() {
    printf '\n## %s\n' "$*" | tee -a "$LOG"
}

section "Host"
run uname -a
if [ -r /etc/os-release ]; then
    run sed -n '1,8p' /etc/os-release
fi

section "Tooling"
for tool in gcc make nft iptables ip6tables tcpdump; do
    if command -v "$tool" >/dev/null 2>&1; then
        run "$tool" --version
    else
        echo "missing: $tool" | tee -a "$LOG"
    fi
done

section "Build"
run make -C "$ROOT_DIR" clean
run make -C "$ROOT_DIR" DEBUG=1

section "Static Bug Probes"
awk '
    /udph->len = htons\(udp_payload_size\)/ {
        print "BUG: IPv4 UDP length excludes UDP header at " FILENAME ":" FNR
    }
    /udph->len = udp_payload_size/ {
        print "BUG: IPv6 UDP length excludes UDP header and lacks htons at " FILENAME ":" FNR
    }
    /fs_execute_command\(nft_cmd, 0, nft_conf_buff\);/ {
        count[FILENAME]++
        if (count[FILENAME] > 1) {
            print "BUG: repeated nft ruleset apply at " FILENAME ":" FNR
        }
    }
    FILENAME ~ /ipv6ipt\.c$/ && /"iptables"/ {
        print "BUG: IPv6 iptables setup invokes IPv4 iptables at " FILENAME ":" FNR
    }
    FILENAME ~ /ipv6ipt\.c$/ && /"--icmp-type"/ {
        print "BUG: IPv6 iptables setup uses IPv4 ICMP matcher at " FILENAME ":" FNR
    }
' "$ROOT_DIR"/src/ipv4pkt.c "$ROOT_DIR"/src/ipv6pkt.c \
   "$ROOT_DIR"/src/ipv6nft.c "$ROOT_DIR"/src/ipv6ipt.c | tee -a "$LOG"

section "nft IPv6 Syntax Probe"
if command -v nft >/dev/null 2>&1; then
    NFT_PROBE="$WORK_DIR/fakesip-ip6-bad.nft"
    cat >"$NFT_PROBE" <<'NFT'
table ip6 fakesip_probe {
    chain fs_prerouting {
        type filter hook prerouting priority mangle - 5;
        policy accept;
        icmp type time-exceeded counter drop;
    }
}
NFT
    run nft -c -f "$NFT_PROBE"
    cat >"$NFT_PROBE" <<'NFT'
table ip6 fakesip_probe {
    chain fs_prerouting {
        type filter hook prerouting priority mangle - 5;
        policy accept;
        icmpv6 type time-exceeded counter drop;
    }
}
NFT
    run nft -c -f "$NFT_PROBE"
else
    echo "skip: nft not installed" | tee -a "$LOG"
fi

section "iptables IPv6 Syntax Probe"
if command -v ip6tables-restore >/dev/null 2>&1; then
    BAD_IP6="$WORK_DIR/fakesip-ip6-bad.rules"
    GOOD_IP6="$WORK_DIR/fakesip-ip6-good.rules"
    cat >"$BAD_IP6" <<'RULES'
*mangle
:FAKESIP_PROBE -
-A FAKESIP_PROBE -p icmp --icmp-type 11 -j DROP
COMMIT
RULES
    cat >"$GOOD_IP6" <<'RULES'
*mangle
:FAKESIP_PROBE -
-A FAKESIP_PROBE -p ipv6-icmp --icmpv6-type time-exceeded -j DROP
COMMIT
RULES
    run ip6tables-restore --test "$BAD_IP6"
    run ip6tables-restore --test "$GOOD_IP6"
else
    echo "skip: ip6tables-restore not installed" | tee -a "$LOG"
fi

section "Summary"
echo "Log written to $LOG"
