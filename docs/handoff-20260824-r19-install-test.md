# FakeSIP r19 OpenWrt Install Test Handoff

Date: 2026-08-24 (Asia/Taipei)
Repository: `<local-fakesip-worktree>`
Target: OpenWrt 25.12.5 x86/64 via Debian `<debian-jump-host>`
Scope: FakeSIP and queue 513 only
Status: installed; 45-minute stability window passed; candidate kept installed

## Candidate To Install

```text
fakesip-0.9.1-r19.apk
sha256: ae9ccb82225e093dc415b80e3a015a3355004b0d47e4cf72e9e58d7655322713

luci-app-fakesip-0.9.1-r19.apk
sha256: 2541c05fd04ccd1086e1379272a45b8d5da68a18b5296b2c36f033f55e18a8c9
```

These are dirty-worktree test candidates, not a formal release. The source pin still
points to an older commit, so installation must not be described as a provenance-clean
release.

The first candidate pair was rejected before installation because its LuCI APK metadata
used `arch: all`, which this router does not accept. The rejected hashes were core
`62b48d096c056169bbce945a7043c60020b125b3e6f2b5b9972725ff0097dfd9` and LuCI
`6a923dfdb7d97e515adc9c902ffc5dea4f0f72e9f231ce4a25776d90c24b1df5`.

## Pre-install State

- Earlier snapshot PID `25720` is stale. Immediate pre-install PID: `31113` at
  `2026-08-24T09:05:49Z` (`2026-08-24 17:05:49 Asia/Taipei`); no restart was issued by
  this turn and the cause of the PID change is not established.
- Existing command: silent mode, repeat 1, TTL 3, IPv4 and IPv6, queue 513, two observed
  SIP URIs, and three PPPoE interfaces.
- Immediate read-only queue 513 row: `513 31113 0 2 65531 0 0 468824 1`. The row was
  selected by its parsed first field because OpenWrt prefixes it with whitespace.
- Last read-only WAN sample: `pppoe-wan2`, `pppoe-wancm`, and `pppoe-wanct` all had zero
  RX/TX errors and drops.
- UCI configuration must remain unchanged.

Rollback preparation is complete:

- Router archive: `/root/fakesip-backup-20260824-r19-candidate-preinstall.tgz`
- Router/Mac archive SHA-256:
  `f0987a3c033dddf63fc89da5b6f1b1a1ca1c9dd3647ed68933921f940f491bc0`
- Mac archive:
  `<local-artifact-dir>/audit-20260824-r19-candidate/router-backup/fakesip-backup-20260824-r19-candidate-preinstall.tgz`
- The replacement target-architecture APKs are on the router under `/tmp` with verified
  SHA-256 values; `apk adbdump` reports `arch: x86_64` for both.
- Pre-install snapshot: FakeSIP was running and package installation had not started;
  RSS was `916 kB`, VmSize `1148 kB`, one thread, and seven FDs.

## Procedure Contract

1. Save a dated router rollback archive containing the current FakeSIP binary, init,
   UCI, LuCI files, package metadata, command line, and relevant checksums.
2. Save a copy of that archive and candidate APKs on the Mac artifact directory.
3. Stop only FakeSIP, install only the two candidate APKs, and restart only FakeSIP.
4. Verify package hashes, installed file hashes, UCI identity, PID, command line, queue
   513, and zero initial drops.
5. Monitor for 45 minutes at one-minute intervals. Record PID, queue packet id,
   backlog/kernel/user drops, CPU, RSS, VmSize, threads, FDs, and each PPP WAN's
   RX/TX error/drop counters.
6. Search only FakeSIP/NFQUEUE-related runtime diagnostics. Do not read or modify
   FakeHTTP, queue 512, mwan policy, or NAT6.

## Window Result

- Valid window start: `2026-08-24T09:18:06+00:00`; end:
  `2026-08-24T10:03:06+00:00`; elapsed `2700` seconds exactly.
- Samples: `46` (sample 0 plus one sample per minute through sample 45). PID `17223`
  remained constant. Queue 513 sequence advanced from `3021` to `18006`; every sample
  reported backlog `0`, kernel drop `0`, user drop `0`, and `anomaly=0`.
- Resource range across all samples: RSS `904 kB`, VmSize `1148 kB`, one thread, five
  FDs. CPU tick delta was `39`.
- Final WAN counters and 45-minute deltas:
  - `pppoe-wan2`: RX `3680581309`, TX `2185647119`, RX packets `3281888`, TX packets
    `3499920`; RX/TX errors and drops all `0`; RX delta `281014677`, TX delta `22055780`.
  - `pppoe-wancm`: RX `3640359756`, TX `744905984`, RX packets `3086967`, TX packets
    `2415577`; RX/TX errors and drops all `0`; RX delta `122495967`, TX delta `56992574`.
  - `pppoe-wanct`: RX `3326670464`, TX `1223535137`, RX packets `3558382`, TX packets
    `3195211`; RX/TX errors and drops all `0`; RX delta `218902402`, TX delta `74692731`.
- End-of-window filtered `logread` and `dmesg` contained no FakeSIP/NFQUEUE/OOM/
  segfault/general-protection lines. The post-window read-only check still showed
  `running`, PID `17223`, RSS `904 kB`, VmSize `1148 kB`, one thread, five FDs, and queue
  513 row `513 17223 0 2 65531 0 0 18086 1`.
- Complete monitor log:
  `<local-artifact-dir>/audit-20260824-r19-candidate/monitor/fakesip-r19-45m-20260824-corrected.log`
  SHA-256 `7b5b37887a8d591ecf93a23f080b5b2777ea4d097511ea59fe7317aa4b4ce32e`.
- Decision: keep the corrected candidate installed. No rollback was needed. The earlier
  parser-invalid window remains excluded and is documented as F-030.
- Post-test cleanup removed the four known temporary candidate APK paths from router
  `/tmp` (the rejected `arch: all` pair and the corrected `x86_64` pair). No known
  candidate temp files remain. The final read-only state at `2026-08-24T10:05:52Z`
  remained `running`, PID `17223`, with command line and installed hashes unchanged.
- Snapshot archive containing the current handoffs, Base64 copies, corrected/rejected APK
  artifacts, rollback archive, and both monitor logs:
  - Mac: `<local-artifact-dir>/audit-20260824-r19-candidate/verification/fakesip-r19-install-test-20260824.tgz`
  - Debian: `/root/fakesip-audit-20260824-r19-install-test-20260824.tgz`

## Install Result

- Installation and service restart completed on 2026-08-24. Verification snapshot:
  `2026-08-24T09:11:08Z` (`2026-08-24 17:11:08 Asia/Taipei`).
- `apk add --allow-untrusted --force-overwrite --force-reinstall` successfully replaced
  both `fakesip-0.9.1-r19` and `luci-app-fakesip-0.9.1-r19` from the corrected target-
  architecture APKs.
- Installed file hashes:
  - `/usr/bin/fakesip`: `1a5473a1a1f23efe97b7cb9d67208e8cc5a636edec2f23f8e87b57bf927876da`
  - `/etc/init.d/fakesip`: `ca8d8412121b593ef9a6973b68205c2136904f4cdb3eecda20cdd8ce7eed6ebb`
  - `/www/luci-static/resources/view/fakesip/fakesip.js`:
    `85156055e56dc6ee26594f3a65f78052fa2c6f513f678f9a087ac3205f2ba0e9`
  - `/etc/config/fakesip`: unchanged at
    `8e3e1fc65eaceefa4b7d4c6e9af0b1f82a0e6f0e5f5892fbaccde9e4f8814447`
- Runtime: `running`, PID `17223`, RSS `836 kB`, VmSize `1148 kB`, one thread, five FDs.
  Command line retained `-1 -4 -6 -s`, both observed SIP URIs, `-n 513`, `-r 1`, `-t 3`,
  and `pppoe-wan2`, `pppoe-wancm`, `pppoe-wanct`.
- Initial queue 513 raw row: `513 17223 0 2 65531 0 0 94 1`; the observed zero fields
  remained zero. `logread` showed only normal FakeSIP startup/version/listening messages;
  the filtered `dmesg` query had no FakeSIP/NFQUEUE/OOM/segfault lines.
- The 45-minute stability window is the remaining test step. FakeHTTP, queue 512, mwan,
  and NAT6 were not read or modified.

## 2026-09-02 Long-run Release Check

The remaining stability step was completed in August and the installed candidate then
continued operating through the September release check. The current service uses the
same binary and LuCI hashes recorded above. A logged normal service exit/start on
2026-09-01 accounts for current PID `2003`; no abnormal exit evidence was found.

During a new 60-second read-only sample, PID stayed `2003`, queue 513 packet ID advanced
by `1142`, and queue depth/kernel drop/user drop stayed `0`. RSS remained `896 kB`,
VmSize `1148 kB`, RssAnon `164 kB`, threads `1`, and descriptors `5`. All configured
PPPoE devices had zero RX/TX errors and drops at both endpoints. Filtered logread and
dmesg contained no OOM, segfault, killed-process, or NFQUEUE failure lines.

This installed OpenWrt 25 candidate therefore meets the runtime release gate. No new
router installation was needed because the rebuilt release APK contains the same core
binary and LuCI view bytes as the installed package.

## 2026-09-05 r20 Install And Runtime Addendum

The OpenWrt 25 router was upgraded in place from both r19 packages to synchronized
`0.9.1-r20` packages. Scope remained FakeSIP and queue 513 only.

Release APKs installed:

```text
2726859439f138b3e69c37123c5b53a8eb640b255acaa7cfbd2a2e246f0cc1a6  fakesip-0.9.1-r20.apk
1413b447831ecf20d35a606cdeafe36a667a5e1b4cfa3885462aa834ded387d6  luci-app-fakesip-0.9.1-r20.apk
```

The pre-install rollback archive is
`fakesip-backup-20260905-092909-r20-preinstall.tgz`, SHA-256
`c3345de7900fc79763bccf9f5e5d1f0f1e4e76ee7d16810e4b6eb1c43ee054da`.
Identical copies were verified on the router, under `<local-backup-dir>`, and on the
Debian jump host. Local extraction validated every recorded file hash and rollback
script syntax.

UCI export SHA-256 remained
`39ab69d7186e434262e5fc59a2b4dae4224894fa92392c8cefb2688e38ff6fbc`
across installation. The service retained outbound IPv4/IPv6, silent mode, the two
configured IMS SIP URIs, queue 513, repeat 1, TTL 3, fwmark/mask, and all three PPPoE
devices. procd reports `term_timeout: 15`.

Installed content hashes match the APK extraction exactly:

```text
4abbcd7f5ee37cd58f62b2e6a0cbe46ebc91b6dbcb14ee6a007fcd10aaaf236b  /usr/bin/fakesip
42b98b1968ce03959c219858def039f5c0fc202228cd04b2ccbe4bb18ca5b3eb  /etc/init.d/fakesip
ae70baf041ddd55fff1914a08fa4bda28208f087b6d4753d24c03cf56c8100fa  /www/luci-static/resources/view/fakesip/fakesip.js
```

Twelve restart cycles each replaced the queue owner in 1.03-1.04 seconds, removed the
old PID, preserved zero queue depth/drops, and logged a normal exit without procd
SIGKILL. A following 15-minute window retained PID 15844. Queue packet ID advanced
270 to 3156 with zero depth, kernel drop, and user drop at all 16 samples. VmSize stayed
1148 kB, RSS settled at 924 kB, and thread/FD counts stayed 1/5. The monitor file SHA-256
is `1c12ecc72df92fd62378b74575900b8e2d57818de686f7133a2cc0572218bf6a`;
verified copies are stored under `<local-artifact-dir>` and on the Debian jump host.

The installed LuCI asset was fetched through the router's actual LAN HTTP listener from
Debian. Its hash matched both the APK and live filesystem, and the new recommended versus
advanced WAN labels and action accessibility attributes were present. Temporary APKs,
the copied monitor, and the verified package-default `.apk-new` were removed afterward.
The service remained running with queue 513 drops at zero.

A later final snapshot at `2026-09-05T09:56:04Z` kept PID 15844, RSS 924 kB, VmSize
1148 kB, one thread, five descriptors, and queue packet ID 4926 with zero depth/kernel/
user drops. No post-monitor FakeSIP anomaly or known temporary r20 file was present.

## 2026-09-06 r21 Install Addendum

The router was upgraded in place from r20 to synchronized `0.9.1-r21` APKs:

```text
7d343329c1732c3231b8903050102634c383e8124243db78ba18e71eebf8f004  fakesip-0.9.1-r21.apk
6b5ccdbc57bb93a2642d3f7634b0cc7d794890eec8adee364106c7e6e3d3e069  luci-app-fakesip-0.9.1-r21.apk
```

The pre-install archive `fakesip-backup-pre-r21-20260906T0040Z.tgz` has SHA-256
`91b43d2e279f066021968b4a0115b8b7063aad1ea9deed5fa3e7c93f196c16a3`;
identical copies were verified on router, Debian, and local backup storage. It remains
private because it contains device configuration.

UCI SHA-256 remained
`39ab69d7186e434262e5fc59a2b4dae4224894fa92392c8cefb2688e38ff6fbc`.
The service retained both observed SIP URIs, three PPPoE devices, outbound IPv4/IPv6,
silent mode, queue 513, repeat 1, TTL 3, and fwmark/mask. Installed LMO, LuCI JS, binary,
and init hashes matched APK extraction.

After almost six hours, PID 29708 was unchanged and queue packet ID advanced from 210 to
259760 with zero depth, kernel drop, and user drop. VmSize was 1148 kB, RSS 852 kB,
RssAnon 164 kB, threads 1, and descriptors 5. No filtered severe runtime diagnostic was
present. Temporary r21 APKs and the reviewed package-default `.apk-new` were removed.

## 2026-09-06 r21 Publication Check

The installed candidate became the published `v0.9.1-openwrt-r21` release without a
binary rebuild. Freshly downloaded GitHub assets reproduced the two recorded APK hashes,
so the tested router installation and public artifacts are byte-identical.

## 2026-09-09 Local Gemini CLI Setup

The host Gemini CLI was upgraded from 0.53.0 to stable 0.59.0. A clean OAuth prompt test
failed at authentication with `UNSUPPORTED_CLIENT` and made no model request. The global
selected auth type is now `gemini-api-key`. The `gemini-authkey` Keychain launcher passed
`sh -n`, resolves from a fresh Bash login shell, and reports the expected help text. No
Gemini key was available, so a live API-key request was not and could not be claimed.
