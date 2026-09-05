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

## Published Release Verification

- Release URL:
  `https://github.com/alzpqm/FakeSIP/releases/tag/v0.9.1-openwrt-r19`.
- Release state: published, non-draft, non-prerelease.
- Annotated tag object: `b71650917836a5a6531785714057a3edbcea3344`.
- Dereferenced tag commit:
  `af2220a54b81e80af5c56e083bd08f819ab6d9b2`.
- Remote release inventory: four package assets plus `SHA256SUMS`.
- All five assets were downloaded from GitHub into a new temporary directory.
- The four downloaded packages passed the published `SHA256SUMS` file byte for byte.
- GitHub's asset digest fields match the four package hashes listed above.
- The release commit and annotated tag use `Codex <codex@local.invalid>` rather than a
  personal author identity.

The published tag remains immutable. Post-release verification notes and any errors in
the verification procedure are recorded on the release branch after the tagged commit.

## 2026-09-05 r20 Candidate Addendum

- Functional source and package pin:
  `8f000525b1fa2711a2659810df397ebdcc21d7f7`.
- Recipe head used by the clean builds:
  `6116df735d7f7cf0d90c544bd31e5aab53cf393b`.
- Core and LuCI package versions: `0.9.1-r20`.

Fresh OpenWrt 25.12.5 x86_64 APK and OpenWrt 22.03.7 x86_64 IPK builds produced:

```text
2726859439f138b3e69c37123c5b53a8eb640b255acaa7cfbd2a2e246f0cc1a6  fakesip-0.9.1-r20.apk
1413b447831ecf20d35a606cdeafe36a667a5e1b4cfa3885462aa834ded387d6  luci-app-fakesip-0.9.1-r20.apk
8105023e53035d677c49e0fd2060a5691165043319055b77fa0f47f24514f881  fakesip_0.9.1-20_x86_64.ipk
51b80158024dbc643f9067e4faa1316ee285b6555f0d754e96b7cb8f7352c67f  luci-app-fakesip_0.9.1-20_all.ipk
```

APK metadata reports x86_64 for both packages, as required by the tested OpenWrt 25 apk
manager. IPK metadata reports x86_64 core and architecture-independent LuCI. Inspection
verified dependencies, neutral source metadata, root ownership, expected file modes, and
privacy-clean content. The OpenWrt 25 APK bytes were installed and matched against live
core/init/LuCI files. Publication followed the final committed privacy scan and is
recorded below.

### r20 Published Release Verification

- Release URL:
  `https://github.com/alzpqm/FakeSIP/releases/tag/v0.9.1-openwrt-r20`.
- Release state: published, non-draft, non-prerelease.
- Annotated tag object: `faf587a50d6a1ce8d40d953d2c44a5500eb495d4`.
- Dereferenced tag commit:
  `84092aeea6079ea0458ef482aaf154a4cbf0f1df`.
- The annotated tagger is `Codex <codex@local.invalid>`.
- Remote inventory: four package assets plus `SHA256SUMS`.
- GitHub digest fields match all four package hashes above. `SHA256SUMS` has SHA-256
  `43b766de39909f1f86f10aac9d32b55f0e63247be42f67090bcbb2377f198d5f`.
- All five assets were downloaded into a fresh temporary directory; the four packages
  passed the downloaded checksum file byte for byte.
- Pull request 7 integrated the release branch into the default branch at anonymous merge
  commit `bc254fef86e485006ce8a883dbe9b1261f4e239d`.
