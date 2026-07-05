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
    grep -Eq "$pattern" "$file" || fail "missing pattern '$pattern' in $file"
}

require_file "$PKG_DIR/Makefile"
require_file "$PKG_DIR/files/fakesip.config"
require_file "$PKG_DIR/files/fakesip.init"
require_file "$ROOT_DIR/openwrt/README.md"
require_file "$LUCI_DIR/Makefile"
require_file "$LUCI_DIR/root/usr/share/luci/menu.d/luci-app-fakesip.json"
require_file "$LUCI_DIR/root/usr/share/rpcd/acl.d/luci-app-fakesip.json"
require_file "$LUCI_DIR/root/www/luci-static/resources/view/fakesip/fakesip.js"

require_executable "$PKG_DIR/files/fakesip.init"

sh -n "$PKG_DIR/files/fakesip.init"
if command -v node >/dev/null 2>&1; then
    node --check "$LUCI_DIR/root/www/luci-static/resources/view/fakesip/fakesip.js" >/dev/null
    node -e "JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'))" \
        "$LUCI_DIR/root/usr/share/luci/menu.d/luci-app-fakesip.json"
    node -e "JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'))" \
        "$LUCI_DIR/root/usr/share/rpcd/acl.d/luci-app-fakesip.json"
else
    printf 'WARN: node is unavailable; skipping LuCI JS and JSON syntax checks.\n'
fi

require_grep 'BuildPackage,fakesip' "$PKG_DIR/Makefile"
require_grep 'libnetfilter-queue' "$PKG_DIR/Makefile"
require_grep 'fakesip.config' "$PKG_DIR/Makefile"
require_grep 'fakesip.init' "$PKG_DIR/Makefile"
require_grep 'kmod-nft-queue' "$ROOT_DIR/openwrt/README.md"
require_grep 'config fakesip' "$PKG_DIR/files/fakesip.config"
require_grep "option ipv6 '1'" "$PKG_DIR/files/fakesip.config"
require_grep 'USE_PROCD=1' "$PKG_DIR/files/fakesip.init"
require_grep 'network_get_device' "$PKG_DIR/files/fakesip.init"
require_grep 'BuildPackage,luci-app-fakesip' "$LUCI_DIR/Makefile"
require_grep 'admin/services/fakesip' "$LUCI_DIR/root/usr/share/luci/menu.d/luci-app-fakesip.json"
require_grep 'luci-app-fakesip' "$LUCI_DIR/root/usr/share/rpcd/acl.d/luci-app-fakesip.json"
require_grep 'form.Map..fakesip' "$LUCI_DIR/root/www/luci-static/resources/view/fakesip/fakesip.js"
require_grep "o.default = '1';" "$LUCI_DIR/root/www/luci-static/resources/view/fakesip/fakesip.js"

printf 'OpenWrt package smoke test passed.\n'
