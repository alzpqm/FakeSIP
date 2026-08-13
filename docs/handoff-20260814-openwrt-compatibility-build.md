# FakeSIP OpenWrt Build Handoff

Date: 2026-08-14 (Asia/Taipei)
Repository: /Users/sirtungshenghsiao/Documents/fakesip
Implementation commit: 0a27d0080ffe3794db1030e37bfbfdf120048b15
Planned release tag: v0.9.1-openwrt-r18

## Build changes

- OpenWrt core Makefile release changed to 0.9.1-r18.
- LuCI Makefile changed from its separate 1.0.0 line to 0.9.1-r18.
- OpenWrt runtime dependencies now include the NFQUEUE kernel module and
  backend-specific nftables or iptables packages.
- LuCI dependencies explicitly include luci-base and rpcd-mod-file.
- LuCI JavaScript has fallbacks for the older 19.07 section UI and
  notification APIs.
- tools/build-openwrt-ipk.sh builds IPK packages from a matching SDK, feeds,
  and local recipes, then restores SDK configuration and symlinks.
- tools/build-openwrt-apk.sh derives both package versions from the two
  Makefiles.

The IPK helper avoids building the full kernel package graph from an SDK. The
kernel dependencies remain in package metadata and must come from the target
release feed. It builds the user-space NFQUEUE libraries first, then the two
local packages with NO_DEPS=1.

## Verified artifacts

Artifacts are stored under:

/Users/sirtungshenghsiao/Documents/fakesip-artifacts/openwrt-0.9.1-r18-20260814

SHA-256 values:

```text
af11c32e9e948690d53fa648a72d459b3a08956b26116a549fb1f73c3a2ad5a7  ipk-22.03.7/fakesip_0.9.1-18_x86_64.ipk
b2ff1b64b8fdf8cabfe805b864dfd567a5287fb9169f463e1984980b7f6e3ad7  ipk-22.03.7/luci-app-fakesip_0.9.1-18_x86_64.ipk
1a66165233acaf918d523039b6982f4086c94a4c1706b4b3ab6c0e2891a17a3b  apk-25.12.5/fakesip-0.9.1-r18.apk
40e9afeab15b2af9f3482d262719a2a08210648d3b4b87c2efff2ee2f42b34e4  apk-25.12.5/luci-app-fakesip-0.9.1-r18.apk
46cc694c5d2bab78bab3db68c2d006b681c9c68b85c8f383cfa6494935537ff4  router/fakesip-backup-20260814-r18.tgz
```

The final 22.03.7 IPK helper run exited zero. Its control metadata was
checked for version 0.9.1-18, runtime dependencies, and root ownership. The
final 25.12.5 APK metadata was checked with apk tools and extracted files were
also checked for root ownership. Earlier failed SDK attempts are discarded
evidence and are not release artifacts.

## Local checks

The following checks passed after the source changes:

- tools/openwrt-package-smoke-test.sh
- SKIP_CLI_TESTS=1 tools/core-regression-test.sh
- node --check and tests/test_luci_fakesip.js
- sh -n on package and test scripts
- git diff --check

The core regression script explicitly skipped Linux-only CLI parser assertions
on macOS. The deliberate invalid-input and rollback errors printed by the
regression suite are expected test injections; the suite exited zero.
