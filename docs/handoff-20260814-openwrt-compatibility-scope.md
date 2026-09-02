# FakeSIP OpenWrt Compatibility Handoff

Date: 2026-08-14 (Asia/Taipei)
Repository: <local-fakesip-worktree>
Branch: codex/fakesip-bug-findings
Implementation commit: 0a27d0080ffe3794db1030e37bfbfdf120048b15
Planned release tag: v0.9.1-openwrt-r18

## Release version

Both OpenWrt packages use one version source:

- PKG_VERSION: 0.9.1
- PKG_RELEASE: 18
- Published package version: 0.9.1-r18

The core and LuCI Makefiles are checked for equality by the package smoke
test. The APK builder reads both Makefiles instead of carrying a second
version string.

## Supported release range

The compatibility claim is OpenWrt 19.07 through 25.12.

| Release | Format | Default firewall | FakeSIP backend setting |
| --- | --- | --- | --- |
| 25.12 | APK | firewall4/nftables | use_iptables=0 |
| 24.10, 23.05, 22.03 | IPK | firewall4/nftables | use_iptables=0 |
| 21.02, 19.07 | IPK | firewall3/iptables | use_iptables=1 |

OpenWrt 18.06 and older are not claimed. They need a separate LuCI API and
packaging port. The 19.07 and 21.02 paths use the legacy iptables backend;
22.03 and newer use nftables by default. The core binary contains both
backends.

## Scope boundary

The exact native builds verified here are OpenWrt 22.03.7 x86_64 IPK and
OpenWrt 25.12.5 x86_64 APK. Other releases in the compatibility matrix still
require a matching SDK and target package feeds before deployment. No claim is
made for another architecture without building that target.

The install test used the Debian jump host and router <openwrt-router>:<router-ssh-port>. It
did not stop, restart, read, or modify FakeHTTP or queue 512. Only FakeSIP and
queue 513 were changed during installation.
