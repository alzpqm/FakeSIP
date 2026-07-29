#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PKG_DIR="$ROOT_DIR/openwrt/fakesip"
LUCI_DIR="$ROOT_DIR/openwrt/luci-app-fakesip"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

require_file() {
    [ -f "$1" ] || fail "missing file: $1"
}

require_executable() {
    [ -x "$1" ] || fail "not executable: $1"
}

require_grep() {
    pattern="$1"
    file="$2"
    grep -Eq -- "$pattern" "$file" || fail "missing pattern '$pattern' in $file"
}

forbid_grep() {
    pattern="$1"
    file="$2"
    if grep -Eq -- "$pattern" "$file"; then
        fail "unexpected pattern '$pattern' in $file"
    fi
}

require_file "$PKG_DIR/Makefile"
require_file "$PKG_DIR/files/fakesip.config"
require_file "$PKG_DIR/files/fakesip.init"
require_file "$ROOT_DIR/openwrt/README.md"
require_file "$LUCI_DIR/Makefile"
require_file "$LUCI_DIR/root/usr/share/luci/menu.d/luci-app-fakesip.json"
require_file "$LUCI_DIR/root/usr/share/rpcd/acl.d/luci-app-fakesip.json"
require_file "$LUCI_DIR/root/www/luci-static/resources/view/fakesip/fakesip.js"
require_file "$ROOT_DIR/tests/test_luci_fakesip.js"

require_executable "$PKG_DIR/files/fakesip.init"

sh -n "$PKG_DIR/files/fakesip.init"
sh "$ROOT_DIR/tests/test_openwrt_init.sh"
if command -v node >/dev/null 2>&1; then
    node --check "$LUCI_DIR/root/www/luci-static/resources/view/fakesip/fakesip.js" >/dev/null
    node -e "JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'))" \
        "$LUCI_DIR/root/usr/share/luci/menu.d/luci-app-fakesip.json"
    node -e "JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'))" \
        "$LUCI_DIR/root/usr/share/rpcd/acl.d/luci-app-fakesip.json"
	node "$ROOT_DIR/tests/test_luci_fakesip.js" \
		"$LUCI_DIR/root/www/luci-static/resources/view/fakesip/fakesip.js" \
		"$LUCI_DIR/root/usr/share/rpcd/acl.d/luci-app-fakesip.json"
else
    printf 'WARN: node is unavailable; skipping LuCI JS and JSON syntax checks.\n'
fi

require_grep 'BuildPackage,fakesip' "$PKG_DIR/Makefile"
require_grep 'libnetfilter-queue' "$PKG_DIR/Makefile"
require_grep 'fakesip.config' "$PKG_DIR/Makefile"
require_grep 'fakesip.init' "$PKG_DIR/Makefile"
require_grep 'PKG_RELEASE:=16' "$PKG_DIR/Makefile"
require_grep 'PKG_SOURCE_VERSION:=54b5f4a8adc0801f0a8fca24cd3ade532ada93ee' "$PKG_DIR/Makefile"
require_grep 'kmod-nft-queue' "$ROOT_DIR/openwrt/README.md"
require_grep 'config fakesip' "$PKG_DIR/files/fakesip.config"
require_grep "option ipv6 '1'" "$PKG_DIR/files/fakesip.config"
require_grep "option silent '1'" "$PKG_DIR/files/fakesip.config"
require_grep "option repeat '1'" "$PKG_DIR/files/fakesip.config"
require_grep "option sip_profile 'china_all'" "$PKG_DIR/files/fakesip.config"
require_grep "option interface_mode 'network'" "$PKG_DIR/files/fakesip.config"
require_grep 'USE_PROCD=1' "$PKG_DIR/files/fakesip.init"
require_grep 'network_get_device' "$PKG_DIR/files/fakesip.init"
require_grep 'start_instance main' "$PKG_DIR/files/fakesip.init"
require_grep 'ims\.mnc000\.mcc460\.3gppnetwork\.org' "$PKG_DIR/files/fakesip.init"
require_grep 'ims\.mnc001\.mcc460\.3gppnetwork\.org' "$PKG_DIR/files/fakesip.init"
require_grep 'ims\.mnc003\.mcc460\.3gppnetwork\.org' "$PKG_DIR/files/fakesip.init"
require_grep 'FS_FAKE_IPV4_ID' "$ROOT_DIR/include/ipv4pkt.h"
require_grep 'FS_FAKE_IPV6_FLOW_WORD' "$ROOT_DIR/include/ipv6pkt.h"
require_grep '@th,96,16' "$ROOT_DIR/src/ipv4nft.c"
require_grep '@th,64,32' "$ROOT_DIR/src/ipv6nft.c"
forbid_grep 'ipt_.*icmp_cmd' "$ROOT_DIR/src/ipv4ipt.c"
forbid_grep 'ipt_.*icmp_cmd' "$ROOT_DIR/src/ipv6ipt.c"
require_grep 'BuildPackage,luci-app-fakesip' "$LUCI_DIR/Makefile"
require_grep 'PKG_RELEASE:=10' "$LUCI_DIR/Makefile"
require_grep 'admin/services/fakesip' "$LUCI_DIR/root/usr/share/luci/menu.d/luci-app-fakesip.json"
require_grep 'luci-app-fakesip' "$LUCI_DIR/root/usr/share/rpcd/acl.d/luci-app-fakesip.json"
require_grep 'form.Map..fakesip' "$LUCI_DIR/root/www/luci-static/resources/view/fakesip/fakesip.js"
require_grep "form.NamedSection, 'main', 'fakesip'" "$LUCI_DIR/root/www/luci-static/resources/view/fakesip/fakesip.js"
require_grep "form.ListValue, 'sip_profile'" "$LUCI_DIR/root/www/luci-static/resources/view/fakesip/fakesip.js"
require_grep "widgets.NetworkSelect, 'network'" "$LUCI_DIR/root/www/luci-static/resources/view/fakesip/fakesip.js"
require_grep "widgets.DeviceSelect, 'interface'" "$LUCI_DIR/root/www/luci-static/resources/view/fakesip/fakesip.js"
require_grep "form.ListValue, 'interface_mode'" "$LUCI_DIR/root/www/luci-static/resources/view/fakesip/fakesip.js"
forbid_grep 'addremove = true' "$LUCI_DIR/root/www/luci-static/resources/view/fakesip/fakesip.js"
require_grep "o.default = '1';" "$LUCI_DIR/root/www/luci-static/resources/view/fakesip/fakesip.js"
require_grep "range\\(1,65535\\)" "$LUCI_DIR/root/www/luci-static/resources/view/fakesip/fakesip.js"
forbid_grep 'range\(1,4294967295\)' "$LUCI_DIR/root/www/luci-static/resources/view/fakesip/fakesip.js"
require_grep "fs.exec\('/etc/init.d/fakesip', \[ 'status' \]\)" "$LUCI_DIR/root/www/luci-static/resources/view/fakesip/fakesip.js"
forbid_grep 'fs.exec_direct' "$LUCI_DIR/root/www/luci-static/resources/view/fakesip/fakesip.js"
forbid_grep 'window.location.reload' "$LUCI_DIR/root/www/luci-static/resources/view/fakesip/fakesip.js"
require_grep 'poll.add\(this.statusPoll, 5\)' "$LUCI_DIR/root/www/luci-static/resources/view/fakesip/fakesip.js"
forbid_grep 'node.insertBefore\(this.renderStatusPanel' "$LUCI_DIR/root/www/luci-static/resources/view/fakesip/fakesip.js"
forbid_grep 'nbytes < 0 && errno != EPERM' "$ROOT_DIR/src/rawsend.c"
require_grep '^    if \(nbytes < 0\) \{' "$ROOT_DIR/src/rawsend.c"
require_grep 'if \(g_ctx.daemon && g_ctx.logfp == stderr\)' "$ROOT_DIR/src/mainfun.c"
require_grep "has no usable interface" "$PKG_DIR/files/fakesip.init"
require_grep 'type f -o -type l' "$ROOT_DIR/tools/build-openwrt-apk.sh"
require_grep 'chown -R 0:0' "$ROOT_DIR/tools/build-openwrt-apk.sh"
require_grep '--script "post-install:' "$ROOT_DIR/tools/build-openwrt-apk.sh"
require_grep '--script "pre-deinstall:' "$ROOT_DIR/tools/build-openwrt-apk.sh"
require_grep 'default_postinst' "$ROOT_DIR/tools/build-openwrt-apk.sh"
require_grep 'default_prerm' "$ROOT_DIR/tools/build-openwrt-apk.sh"

logger_setup_line=$(grep -n 'res = fs_logger_setup();' "$ROOT_DIR/src/mainfun.c" | tail -n 1 | cut -d: -f1)
daemon_silent_line=$(grep -n 'if (g_ctx.daemon && g_ctx.logfp == stderr)' "$ROOT_DIR/src/mainfun.c" | cut -d: -f1)
[ -n "$logger_setup_line" ] && [ -n "$daemon_silent_line" ] &&
	[ "$logger_setup_line" -lt "$daemon_silent_line" ] ||
	fail "daemon silent-mode decision must follow logger setup"

resolved_iface_line=$(grep -n 'if \[ -z "$FS_IFACES_ADDED" \]' "$PKG_DIR/files/fakesip.init" | cut -d: -f1)
open_instance_line=$(grep -n 'procd_open_instance "$section"' "$PKG_DIR/files/fakesip.init" | cut -d: -f1)
[ -n "$resolved_iface_line" ] && [ -n "$open_instance_line" ] &&
	[ "$resolved_iface_line" -lt "$open_instance_line" ] ||
	fail "usable interfaces must be validated before opening a procd instance"

direction_guard_line=$(grep -n 'has no enabled traffic direction' "$PKG_DIR/files/fakesip.init" | cut -d: -f1)
family_guard_line=$(grep -n 'has no enabled IP family' "$PKG_DIR/files/fakesip.init" | cut -d: -f1)
[ -n "$direction_guard_line" ] && [ -n "$family_guard_line" ] &&
	[ "$direction_guard_line" -lt "$open_instance_line" ] &&
	[ "$family_guard_line" -lt "$open_instance_line" ] ||
	fail "traffic direction and IP family guards must precede procd startup"

printf 'OpenWrt package smoke test passed.\n'
