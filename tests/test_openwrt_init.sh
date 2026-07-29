#!/bin/sh
# rc.common does not enable errexit; several optional append helpers return 1
# when an option is disabled, so the harness must preserve that behavior.
set -u

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
INIT_SCRIPT="$ROOT_DIR/openwrt/fakesip/files/fakesip.init"
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/fakesip-init-test.XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT HUP INT TERM

fail() {
	printf 'FAIL: %s\n' "$*" >&2
	exit 1
}

assert_eq() {
	expected="$1"
	actual="$2"
	message="$3"
	[ "$actual" = "$expected" ] ||
		fail "$message (expected '$expected', got '$actual')"
}

assert_contains() {
	haystack="$1"
	needle="$2"
	message="$3"
	case "$haystack" in
		*"$needle"*) ;;
		*) fail "$message (missing '$needle')" ;;
	esac
}

config_get() {
	_dest="$1"
	_option="$3"
	eval "_value=\${CFG_${_option}-}"
	eval "$_dest=\"\$_value\""
}

config_get_bool() {
	_dest="$1"
	_default="$4"
	config_get "$_dest" "$2" "$3"
	eval "_value=\${$_dest}"
	[ -n "$_value" ] || eval "$_dest=\$_default"
}

config_list_foreach() {
	_option="$2"
	_callback="$3"
	shift 3
	eval "_values=\${CFG_${_option}-}"
	for _value in $_values; do
		"$_callback" "$_value" "$@"
	done
}

network_get_device() {
	_dest="$1"
	_network="$2"
	eval "_device=\${NET_${_network}-}"
	[ -n "$_device" ] || return 1
	eval "$_dest=\"\$_device\""
}

logger() {
	shift 2
	LOG_MESSAGES="${LOG_MESSAGES}${LOG_MESSAGES:+\n}$*"
}

procd_open_instance() {
	PROCD_OPEN=$((PROCD_OPEN + 1))
	PROCD_SECTION="$1"
}

procd_set_param() {
	if [ "$1" = command ]; then
		PROCD_PROGRAM="$2"
	fi
}

procd_append_param() {
	[ "$1" = command ] || return 0
	shift
	while [ "$#" -gt 0 ]; do
		case "$1" in
				-i)
				[ "$#" -ge 2 ] || fail "-i is missing its interface"
				shift
					PROCD_IFACES="${PROCD_IFACES}${PROCD_IFACES:+ }$1"
					;;
				-u)
					[ "$#" -ge 2 ] || fail "-u is missing its SIP URI"
					shift
					PROCD_URIS="${PROCD_URIS}${PROCD_URIS:+ }$1"
					;;
			-a)
				PROCD_ALL=1
				;;
		esac
		shift
	done
}

procd_close_instance() {
	PROCD_CLOSE=$((PROCD_CLOSE + 1))
}

reset_case() {
	CFG_enabled=1
	CFG_all_interfaces=0
	CFG_network=
	CFG_interface=
	CFG_sip_profile=standard
	CFG_sip_uri=
	CFG_payload_file=
	CFG_inbound=
	CFG_outbound=
	CFG_ipv4=
	CFG_ipv6=
	CFG_no_hop_estimate=
	CFG_skip_firewall=
	CFG_use_iptables=
	CFG_silent=
	CFG_queue_num=
	CFG_fwmark=
	CFG_fwmask=
	CFG_repeat=
	CFG_ttl=
	CFG_dynamic_pct=
	CFG_log_file=
	NET_wan=
	NET_ghostnet0=
	PROCD_OPEN=0
	PROCD_CLOSE=0
	PROCD_SECTION=
	PROCD_PROGRAM=
	PROCD_IFACES=
	PROCD_URIS=
	PROCD_ALL=0
	LOG_MESSAGES=
}

# The OpenWrt library imports are replaced by the mocks above.
sed '/^\. \/lib\/functions/d' "$INIT_SCRIPT" > "$TMP_DIR/fakesip.init"
. "$TMP_DIR/fakesip.init"

reset_case
CFG_enabled=0
CFG_interface=pppoe-disabled
start_instance main
assert_eq 0 "$PROCD_OPEN" "disabled sections must not open a procd instance"

reset_case
CFG_inbound=0
CFG_outbound=0
CFG_interface=pppoe-wan
start_instance main
assert_eq 0 "$PROCD_OPEN" "an empty traffic direction pair must not start"
assert_contains "$LOG_MESSAGES" "has no enabled traffic direction" \
	"an empty traffic direction pair must be logged"

reset_case
CFG_ipv4=0
CFG_ipv6=0
CFG_interface=pppoe-wan
start_instance main
assert_eq 0 "$PROCD_OPEN" "an empty IP family pair must not start"
assert_contains "$LOG_MESSAGES" "has no enabled IP family" \
	"an empty IP family pair must be logged"

reset_case
CFG_sip_profile=custom
CFG_interface=pppoe-wan
start_instance main
assert_eq 0 "$PROCD_OPEN" "a custom profile without SIP URIs must not start"
assert_contains "$LOG_MESSAGES" "custom SIP profile has no URI" \
	"a custom profile without SIP URIs must be logged"

reset_case
CFG_sip_profile=custom
CFG_sip_uri=sip:user@example.com
CFG_interface=pppoe-wan
start_instance main
assert_eq 1 "$PROCD_OPEN" "a populated custom SIP profile must start"
assert_eq sip:user@example.com "$PROCD_URIS" \
	"a custom SIP profile must append its configured URI"

reset_case
CFG_sip_profile=standard
CFG_sip_uri=sip:stale@example.com
CFG_interface=pppoe-wan
start_instance main
assert_eq 1 "$PROCD_OPEN" "the standard SIP profile must start"
assert_eq "" "$PROCD_URIS" \
	"the standard SIP profile must ignore stale custom URIs"

reset_case
start_instance main
assert_eq 0 "$PROCD_OPEN" "an empty interface configuration must not start"
assert_contains "$LOG_MESSAGES" "has no network or interface" \
	"an empty interface configuration must be logged"

reset_case
CFG_network=ghostnet0
start_instance main
assert_eq 0 "$PROCD_OPEN" "unresolved logical networks must not start"
assert_contains "$LOG_MESSAGES" "network 'ghostnet0' has no active device" \
	"an unresolved logical network must be logged"
assert_contains "$LOG_MESSAGES" "has no usable interface" \
	"a section without resolved interfaces must be logged"

reset_case
CFG_network="wan ghostnet0"
CFG_interface="pppoe-manual pppoe-wan"
NET_wan=pppoe-wan
start_instance main
assert_eq 1 "$PROCD_OPEN" "a resolved interface must start one instance"
assert_eq 1 "$PROCD_CLOSE" "a resolved interface must close one instance"
assert_eq main "$PROCD_SECTION" "the configured section name must be preserved"
assert_eq /usr/bin/fakesip "$PROCD_PROGRAM" "the instance must run FakeSIP"
assert_eq "pppoe-wan pppoe-manual" "$PROCD_IFACES" \
	"resolved and direct interfaces must be ordered and deduplicated"

reset_case
CFG_interface="pppoe-future pppoe-future"
start_instance main
assert_eq 1 "$PROCD_OPEN" "direct PPP names must be accepted before they exist"
assert_eq pppoe-future "$PROCD_IFACES" "direct interface names must be deduplicated"

reset_case
CFG_interface=bad/name
start_instance main
assert_eq 0 "$PROCD_OPEN" "invalid direct interface names must not start"
assert_contains "$LOG_MESSAGES" "invalid interface 'bad/name'" \
	"invalid direct interface names must be logged"

reset_case
CFG_interface=abcdefghijklmnop
start_instance main
assert_eq 0 "$PROCD_OPEN" "16-byte direct interface names must not start"
assert_contains "$LOG_MESSAGES" "invalid interface 'abcdefghijklmnop'" \
	"overlong direct interface names must be logged"

reset_case
CFG_interface=abcdefghijklmno
start_instance main
assert_eq 1 "$PROCD_OPEN" "15-byte direct interface names must remain valid"
assert_eq abcdefghijklmno "$PROCD_IFACES" \
	"the maximum valid interface name must be preserved"

reset_case
CFG_all_interfaces=1
start_instance main
assert_eq 1 "$PROCD_OPEN" "all-interfaces mode must start without interface lists"
assert_eq 1 "$PROCD_ALL" "all-interfaces mode must append -a"
assert_eq "" "$PROCD_IFACES" "all-interfaces mode must not append -i"

printf 'OpenWrt init behavior tests passed.\n'
