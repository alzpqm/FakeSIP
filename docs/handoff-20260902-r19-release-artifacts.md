# FakeSIP r19 Release Artifact Handoff

Date: 2026-09-02 (Asia/Taipei)

## Source

- Functional source: `e9b87e0791b43f1d9677420649614a5116fd90e8`.
- OpenWrt source pin: the same functional source commit.
- Package/tooling head before final handoff commit:
  `d3294825b52d8af11c6b30c7353f77336fe2b601`.
- Core package version: `0.9.1-r19`.
- LuCI package version: `0.9.1-r19`.

## Final Assets

```text
c31a2d5e99987cb5ba95c7ef45ee31595e603af29938fa0761e89e608f9ae5ca  fakesip-0.9.1-r19.apk
9a85ac46cdea29ec61bf63cf93039758cd275107ac6c8e8668104eb55d26c937  luci-app-fakesip-0.9.1-r19.apk
e101310918729923ca3fbf333229dcc2ecd377294c11b70ab4c6962fd5e092f2  fakesip_0.9.1-19_x86_64.ipk
6e6900856201860c5003c05bdf041da49aa463dd9839d08185d45e76048db0c8  luci-app-fakesip_0.9.1-19_all.ipk
```

The APK pair targets OpenWrt 25 x86_64. The IPK pair was built with an OpenWrt 22.03
x86_64 SDK for OpenWrt 24.10 and older package managers. Other architectures require a
matching SDK rebuild.

## Package Inspection

- APK core and LuCI architecture: `x86_64`.
- IPK core architecture: `x86_64`; LuCI architecture: `all`.
- Core config mode: `0600`, owner/group `root:root`.
- Init and binary modes: `0755`, owner/group `root:root`.
- LuCI and ACL files: `0644`, owner/group `root:root`.
- APK core binary SHA-256:
  `1a5473a1a1f23efe97b7cb9d67208e8cc5a636edec2f23f8e87b57bf927876da`.
- APK LuCI view SHA-256:
  `85156055e56dc6ee26594f3a65f78052fa2c6f513f678f9a087ac3205f2ba0e9`.
- The two APK content hashes match the files installed on the tested OpenWrt 25 router.
- IPK control metadata contains only neutral `package/...` source paths.

## Verification

Passed gates:

- local core unit suite with explicit CLI skip on macOS;
- OpenWrt init/LuCI/package smoke and syntax checks;
- Debian debug build and full CLI/core suite;
- Debian ASan/LSan/UBSan unit suite;
- GCC analyzer build;
- Debian smoke, nft syntax, and nft rollback integration;
- OpenWrt 25 APK cross-build and metadata/content inspection;
- OpenWrt 22.03 IPK cross-build and metadata/content inspection;
- committed snapshot privacy scan and Base64 decode/compare.

The OpenWrt 22.03 SDK emits existing feed/Kconfig type-redefinition and missing optional
dependency warnings. The selected package builds completed with exit 0 and final package
inspection passed. Debian lacks iptables/ip6tables, so the nft rollback integration was
run; the iptables rollback path was not newly repeated in this release cycle.
