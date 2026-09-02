# FakeSIP Bug Audit Context - 2026-08-24

## Purpose

This file is the durable context snapshot written immediately after a model context
compaction. It separates committed source, uncommitted experiments, installed router
state, and evidence gaps. Do not infer one state from another.

## Repository State

- Workspace: `<local-fakesip-worktree>`
- Branch: `codex/fakesip-bug-findings`
- HEAD: `32cc1c17f63aac9f9d2933d57e75baf18d23f66b`
- Exact tag at HEAD: `v0.9.1-openwrt-r18`
- Required Git author for any future commit: `Codex <codex@local.invalid>`
- No commit, tag, push, or release is authorized by the current bug-audit request.
- The worktree is dirty and must not be reset or replaced.

Tracked files modified by the local r19 experiment:

- `openwrt/README.md`
- `openwrt/fakesip/Makefile`
- `openwrt/fakesip/files/fakesip.init`
- `openwrt/luci-app-fakesip/Makefile`
- `openwrt/luci-app-fakesip/root/www/luci-static/resources/view/fakesip/fakesip.js`
- `src/payload.c`
- `tests/test_luci_fakesip.js`
- `tests/test_openwrt_init.sh`
- `tests/test_payload.c`
- `tools/openwrt-package-smoke-test.sh`

There are also twelve untracked 2026-08-18 handoff artifacts: six English Markdown
files and their six base64 copies. They are evidence and must not be deleted.

## Local r19 Experiment

- Core and LuCI package versions are both `0.9.1-r19`.
- The new single profile is `china_sip_observed`.
- It rotates these URIs in configured order:
  1. `sip:user@sipcq16.xnq.r.10086.cn:5260`
  2. `sip:user@sipsc109.r01.rcs.189.cn:5260`
  3. the first URI again
- `src/payload.c` currently treats both observed hosts and `.3gppnetwork.org` as IMS
  payloads and emits IMS-style headers plus AMR SDP.
- The default profile remains `china_all`.
- Documentation labels the observed profile experimental. The observed connections do
  not prove a carrier QoS whitelist or guaranteed rate-limit bypass.
- This r19 source is not committed, pushed, tagged, or released.

## Router State Last Verified on 2026-08-18

- Target: OpenWrt 25.12.5 x86/64 at `<openwrt-router>:<router-ssh-port>` through Debian
  `<debian-jump-host>`.
- Installed packages: `fakesip-0.9.1-r19` and `luci-app-fakesip-0.9.1-r19`.
- Active profile: `china_sip_observed`.
- Last observed PID: 15782. It is historical and must be re-read before any claim
  about current runtime state.
- Last observed command included outbound, IPv4, IPv6, silent mode, repeat 1, TTL 3,
  queue 513, both URIs in order, and interfaces `pppoe-wan2`, `pppoe-wancm`, and
  `pppoe-wanct`.
- A 30-second queue 513 sample advanced from packet id 44 to 62 with backlog, kernel
  drop, and user drop all zero.
- Last observed process metrics: VmRSS 844 kB, VmSize 1148 kB, RssAnon 100 kB,
  one thread, and seven file descriptors.
- Router backup directory: `/root/fakesip-backup-20260818-r19-observed`
- Router backup archive SHA-256:
  `33c036882b2885d3c473dd2aba2dd036f4e89cc938a219e22fd9fbee753f8436`
- Local archive:
  `<local-artifact-dir>/openwrt-0.9.1-r19-observed-20260818/router/fakesip-backup-20260818-r19-observed.tgz`

Do not read or modify FakeHTTP or queue 512 during this audit. Only FakeSIP and queue
513 are in scope.

## r19 Artifact Evidence

- Core APK SHA-256:
  `f98fc0f2a46f3e4395e7f2e7f7ca42dda27f4526d13ce8f39476f8ff66132866`
- LuCI APK SHA-256:
  `8ba9992ed8ff28d84a277ed69cfc6a4c018acdb7e0587adc0cb6ce6a0fe41d7b`
- Local artifact directory:
  `<local-artifact-dir>/openwrt-0.9.1-r19-observed-20260818`
- Debian source copy: `/root/fakesip-r19-observed-20260818`
- Debian output directory: `/root/fakesip-r19-apk-output-20260818`

## Previously Verified r19 Tests

- Core regression with `SKIP_CLI_TESTS=1`: passed on macOS.
- OpenWrt package smoke test: passed.
- LuCI syntax and behavior tests: passed.
- Shell syntax and `git diff --check`: passed.
- OpenWrt SDK x86/64 APK build: passed.
- APK contents, metadata, and root ownership: verified.
- Router queue 513 short runtime check: passed with zero drops.

These are historical results. Current source must be retested before a new conclusion.

## Known Failure That Must Remain Recorded

During the 2026-08-18 APK verification, extraction was first attempted without creating
the destination directories. `apk extract` reported that the core and LuCI destinations
did not exist, and dependent `strings`, `grep`, and `stat` checks then reported missing
files. The harness setup was corrected with `mkdir -p`, after which extraction and all
artifact checks passed. This was a test-harness setup failure, not an APK defect.

Expected fault-injection messages from core regression tests, such as invalid URI,
invalid srcinfo, Broken pipe, and injected nft or iptables setup failures, are not product
test failures when the suite exits zero. They must be labeled as expected injections.

## Current Audit Plan

1. Inventory the dirty worktree and preserve all evidence.
2. Run fresh local and Debian/Linux dynamic and static checks.
3. Independently inspect core, OpenWrt init, LuCI, packaging, and tests.
4. Fix only reproducible defects and add focused regression coverage.
5. Rebuild packages and verify FakeSIP/queue 513 without touching queue 512.
6. Write a complete failures log and final findings handoff.
7. Produce three English Markdown handoffs plus three verified base64 copies for this
   audit, totaling six files.

## Candidate Risks, Not Yet Findings

- IMS host detection currently uses substring matching and may classify lookalike hosts
  as IMS. This requires a focused test before changing code.
- Logging passes the result of `localtime()` directly to `strftime()` without checking
  for NULL. This requires control-flow and test review.
- The payload generator emits IPv4 SDP independently of the outer packet family. This
  may weaken IPv6 camouflage but requires architectural and runtime evidence.
- The package Makefile still pins an older committed source revision while local r19 core
  changes are uncommitted. The direct local APK builder used the worktree, but a normal
  source-fetch SDK build could differ. Do not call this released until source and package
  provenance are synchronized.

## Evidence Rules

- Record every nonzero command, timeout, missing dependency, connection problem, test
  harness mistake, and rollback in the failure handoff.
- Preserve exact command scope and distinguish expected negative tests from real failures.
- Model reviews, including Gemini or local models, are suggestions only. A finding needs
  source control-flow evidence, a reproducer, a test, or runtime evidence.
- Never report an old PID, queue counter, package version, or router state as current
  without rereading it.

## Second Compaction Snapshot on 2026-08-24

This section was appended immediately after a second context compaction. It supersedes
older current-state statements above without deleting their historical evidence.

### Source Fixes Implemented but Not Installed

- `src/payload.c` now parses SIP host boundaries case-insensitively instead of granting
  IMS payload behavior through a substring match. Exact observed hosts and a real
  `.3gppnetwork.org` suffix are accepted; lookalike hosts and query text are rejected.
- `src/rawsend.c` now opens only the socket families required by the selected fake
  direction and IP families. Cleanup also resets cached IPv4 and IPv6 bind indices.
- `src/nfqueue.c` now converts `hw_addrlen` from network byte order, rejects oversized
  link-layer addresses, sets the real `sll_halen`, and clears stale address bytes.
- `src/logging.c` now uses checked `localtime_r()` and `strftime()` results, has a
  deterministic fallback timestamp, and safely falls back to `stderr` when no log file
  is configured.
- The OpenWrt init script now rejects an unknown SIP profile before opening a procd
  instance instead of silently falling back to the standard payload.
- Focused regression tests were added or extended in `tests/test_payload.c`,
  `tests/test_rawsend.c`, `tests/test_nfqueue.c`, `tests/test_logging.c`, and
  `tests/test_openwrt_init.sh`.

These changes exist only in the dirty worktree and Debian audit copy. They have not been
installed on the router, committed, pushed, tagged, or released.

### Fresh Verification Completed

- macOS core regression with explicit CLI skip: passed.
- macOS OpenWrt package smoke test, shell syntax, and `git diff --check`: passed.
- Debian debug build and full core regression including CLI tests: passed.
- Debian ASan, LSan, and UBSan unit suite: passed.
- Debian GCC `-fanalyzer` build: passed without analyzer warnings.
- Debian network namespace smoke test: passed.
- Linux nft rollback integration: passed.
- Debian two-process raw-socket runtime smoke passed for outbound dual-family and
  inbound IPv4-only modes; each process used five file descriptors and exited normally.
- OpenWrt 22.03.7 x86/64 SDK build completed successfully and produced:
  - `/root/fakesip-audit-20260824-ipk22/fakesip_0.9.1-19_x86_64.ipk`
  - `/root/fakesip-audit-20260824-ipk22/luci-app-fakesip_0.9.1-19_x86_64.ipk`

The 22.03 SDK emitted many pre-existing Kconfig type-redefinition and unrelated missing
dependency warnings, but both requested packages were produced and the build exited
zero. Package content and metadata still require explicit inspection.

### Fresh Router Read-Only Health Evidence

- OpenWrt version: 25.12.5 x86/64.
- Installed packages remain `fakesip-0.9.1-r19` and
  `luci-app-fakesip-0.9.1-r19`.
- PID at the latest read: 25720.
- The process remained on queue 513 with outbound IPv4 and IPv6, silent mode, repeat 1,
  TTL 3, both observed SIP URIs, and all three PPP interfaces.
- During a 60-second sample, the queue packet id advanced by 304 while backlog, kernel
  drop, and user drop remained zero. CPU increased by one system tick; memory, seven
  file descriptors, and one thread remained stable.
- All three PPP interfaces retained zero RX/TX errors and drops. Recent targeted logread
  and dmesg searches found no FakeSIP, NFQUEUE, OOM, or segfault anomaly.
- IPv6-tagged ICMP counters had nonzero hits, confirming that the active IPv6 path is not
  absent merely because separate logical `_6` networks exist in LuCI.

This was read-only evidence. No router service, queue rule, package, or configuration was
changed.

### Remaining Gates

- Build and inspect the OpenWrt 25.12 APK artifacts from the same local source.
- Inspect both 22.03 IPKs for metadata, ownership, files, and expected profile content.
- The Debian iptables rollback integration could not run because the Debian host lacks
  `iptables` and `ip6tables`; nft rollback coverage passed.
- LocalAI model runtimes are not installed or active in the local environment, and the
  Gemini Workspace request was rejected by current Code Assist authorization. No model
  review succeeded in this audit.
- The package Makefile source revision still points to an older committed revision.
  Direct local builders use this worktree, but a normal fetched-source build would not
  reproduce these uncommitted fixes. This is a release-provenance blocker.
- Version numbers remain synchronized at r19. Do not bump, install, or call this a formal
  release until provenance and the requested deployment scope are deliberately resolved.

## Final Audit Snapshot on 2026-08-24

The audit is complete. This section is the authoritative continuation state.

### Confirmed Fix Set

1. SIP IMS classification now uses real host boundaries instead of substring matching.
2. Raw-send setup opens only sockets required by the selected direction and IP family.
3. NFQUEUE hardware-address length is converted, bounded, and preserved accurately.
4. Logging handles failed time conversion and an unset log stream.
5. Unknown OpenWrt SIP profiles fail closed before procd instance creation.
6. OpenWrt 25 APK config mode is now 0600, matching IPK and the router.
7. The JavaScript-only LuCI package is architecture `all` in both IPK and APK metadata.

Focused tests were added for the first five items. Package smoke assertions lock the last
two. The existing payload rotation source fix remains covered by an explicit
first/second/third/first regression and by the two-host observed profile order.

### Final Verification

- Local core regression passed with the explicit macOS CLI skip.
- Local init, LuCI, package, JavaScript, shell syntax, and diff gates passed.
- Debian full CLI/core regression, sanitizers, GCC analyzer, namespace smoke, nft
  rollback, and raw-socket runtime modes passed on source hashes identical to the Mac.
- OpenWrt 22.03.7 IPK and OpenWrt 25.12.5 APK builds passed.
- Package integrity, versions, dependencies, architectures, archive ownership, extracted
  ownership, config/binary/init modes, source-file identity, observed hosts, logging
  fallback, and hardware-address guard were verified.
- The accidental Debian `/root` extraction was archived and completely cleaned. Recovery
  archive SHA-256:
  `18dbd10bd7770dbf019d57e41834a064bda2f6858a5d229840ac473575e639be`.
- The Debian iptables rollback test remains unavailable because the shared host has no
  iptables binaries. The nft path passed.
- LocalAI runtimes were unavailable and Gemini Code Assist rejected the current
  authorization. No model review is claimed.

### Candidate Artifacts

```text
646079ff637a90ae3b171450e6f1d73a12d3365457010fb435e5c042a4742f2c  fakesip_0.9.1-19_x86_64.ipk
49595cf533d75b741b4f2ab521b6ca9927cbbc217f893aaa215d45150abb985b  luci-app-fakesip_0.9.1-19_all.ipk
62b48d096c056169bbce945a7043c60020b125b3e6f2b5b9972725ff0097dfd9  fakesip-0.9.1-r19.apk
6a923dfdb7d97e515adc9c902ffc5dea4f0f72e9f231ce4a25776d90c24b1df5  luci-app-fakesip-0.9.1-r19.apk
```

- Debian package directories:
  - `/root/fakesip-audit-20260824-ipk22-fixed`
  - `/root/fakesip-audit-20260824-apk25-fixed`
- Debian combined archive:
  `/root/fakesip-audit-20260824-candidate-artifacts.tgz`
- Combined archive SHA-256:
  `3194a589a6d7fd1ae1f11e85fbfbedc7243461b94754b852ff9a8809187e442e`
- Mac copy:
  `<local-artifact-dir>/audit-20260824-r19-candidate`
- Source and handoff archive on both Debian and Mac:
  `fakesip-audit-20260824-source-and-handoffs.tgz`
- Source and handoff archive SHA-256:
  `0580d35b104dd1205321200f88ea8fdd69e87de77411b90a7d94fe729db34919`

These are test candidates, not release artifacts.

### Router Boundary and Final Health

- No candidate package was installed and no service/configuration change was made.
- The active router remains on the earlier `0.9.1-r19` packages and PID 25720.
- Final 30-second read-only sample: queue id 435337 to 435630; backlog, kernel drop, and
  user drop all zero; RSS 912 kB; VmSize 1148 kB; one thread; seven descriptors; one CPU
  tick added.
- `pppoe-wan2`, `pppoe-wancm`, and `pppoe-wanct` each reported zero RX errors, RX drops,
  TX errors, and TX drops.
- Queue 512, FakeHTTP, mwan, and NAT6 were not read or modified.

### Release Boundary

- Worktree remains dirty and uncommitted.
- No commit, push, tag, pull-request update, GitHub release, or cloud upload occurred.
- Both package recipes remain synchronized at version `0.9.1-r19`.
- `openwrt/fakesip/Makefile` still pins committed source
  `ebe90f7fb191e0fc292006b0da3f28c5ef4a8da5`, which does not contain this dirty fix set.
- Do not install, publish, or call these candidates formal until the source commit is
  reviewed, pushed, pinned, versioned, rebuilt, and reverified.

## OpenWrt Install Test Start on 2026-08-24

The user authorized installing the verified r19 candidate on the OpenWrt 25.12 router
and running a 45-minute FakeSIP-only stability window. This section records the start
state before any device mutation.

- Candidate core APK: `fakesip-0.9.1-r19.apk`, SHA-256
  `ae9ccb82225e093dc415b80e3a015a3355004b0d47e4cf72e9e58d7655322713`.
- Candidate LuCI APK: `luci-app-fakesip-0.9.1-r19.apk`, SHA-256
  `2541c05fd04ccd1086e1379272a45b8d5da68a18b5296b2c36f033f55e18a8c9`.
- Router target: OpenWrt 25.12.5 x86/64 via Debian `<debian-jump-host>`.
- Existing FakeSIP PID before install: 25720.
- Existing queue: 513, backlog/kernel/user drops all zero in the last sample.
- Existing mode: silent, repeat 1, TTL 3, IPv4 plus IPv6, the two observed SIP URIs,
  and `pppoe-wan2`, `pppoe-wancm`, `pppoe-wanct`.
- UCI config must remain byte-identical across installation.
- Scope excludes FakeHTTP, queue 512, mwan policy, and NAT6.

Before installation, create a dated router rollback archive and a local copy. Stop only
FakeSIP during package replacement, install the two APKs with apk-tools, then start only
FakeSIP and verify the new binary, init/LuCI hashes, command line, and queue 513. If the
45-minute window exposes a real regression, restore the saved files/package state and
record the rollback explicitly.

The 45-minute window is not complete at this snapshot.

### Install Preparation Completed

- Router rollback archive:
  `/root/fakesip-backup-20260824-r19-candidate-preinstall.tgz`
- Router and Mac rollback archive SHA-256:
  `f0987a3c033dddf63fc89da5b6f1b1a1ca1c9dd3647ed68933921f940f491bc0`
- Mac rollback copy:
  `<local-artifact-dir>/audit-20260824-r19-candidate/router-backup/fakesip-backup-20260824-r19-candidate-preinstall.tgz`
- Candidate APKs were uploaded through verified raw SSH `dd` streams. Remote and local
  hashes matched the candidate values above.
- FakeSIP has not yet been stopped and no package has yet been installed.

### Immediate Pre-install Reconciliation

- At router time `2026-08-24T09:05:49Z`, the running FakeSIP PID was `31113`; the earlier
  handoff value `25720` was stale and its cause is not established. This turn did not
  restart the service.
- The queue 513 row was present as `513 31113 0 2 65531 0 0 468824 1`; the query must
  parse the first field because the row has leading whitespace. RSS was `916 kB`, VmSize
  `1148 kB`, one thread, and seven FDs. Installation had not started at this point.

### APK Architecture Correction Before Installation

- The first APK transaction was rejected because the LuCI package declared `arch: all`,
  while the router's `/etc/apk/arch` contains only `x86_64`; the transaction was atomic,
  leaving both installed packages unchanged and FakeSIP stopped.
- `tools/build-openwrt-apk.sh` now uses target `ARCH` for both direct APKs. The rebuilt
  Debian/local packages are core SHA-256
  `ae9ccb82225e093dc415b80e3a015a3355004b0d47e4cf72e9e58d7655322713` and LuCI SHA-256
  `2541c05fd04ccd1086e1379272a45b8d5da68a18b5296b2c36f033f55e18a8c9`.
- Router `apk adbdump` reports `arch: x86_64` for both replacement APKs. No package has
  been installed yet; queue 513 is absent and the next action is the corrected install.

### Corrected Install Completed

- The replacement APK transaction completed successfully, followed by starting only
  FakeSIP. Verification at `2026-08-24T09:11:08Z` found PID `17223`, status `running`,
  RSS `836 kB`, VmSize `1148 kB`, one thread, and five FDs.
- Installed hashes match the rebuilt candidate: binary
  `1a5473a1a1f23efe97b7cb9d67208e8cc5a636edec2f23f8e87b57bf927876da`, init
  `ca8d8412121b593ef9a6973b68205c2136904f4cdb3eecda20cdd8ce7eed6ebb`, LuCI view
  `85156055e56dc6ee26594f3a65f78052fa2c6f513f678f9a087ac3205f2ba0e9`, and unchanged
  UCI `8e3e1fc65eaceefa4b7d4c6e9af0b1f82a0e6f0e5f5892fbaccde9e4f8814447`.
- Command-line parameters retained the two observed SIP URIs, queue 513, silent mode,
  repeat 1, TTL 3, IPv4/IPv6, and the three PPPoE devices. Initial queue row was
  `513 17223 0 2 65531 0 0 94 1`; startup logs were normal and filtered dmesg had no
  FakeSIP/NFQUEUE/OOM/segfault lines. The 45-minute window is now pending.

### Valid 45-minute Window Completed

- The corrected window ran from `2026-08-24T09:18:06+00:00` to
  `2026-08-24T10:03:06+00:00`, exactly `2700` seconds, with 46 samples. PID `17223`
  never changed; queue 513 sequence advanced `3021 -> 18006`; backlog, kernel drop, and
  user drop stayed `0` in every sample.
- RSS stayed `904 kB`, VmSize `1148 kB`, threads `1`, FDs `5`; CPU increased by `39`
  ticks. All three PPPoE interfaces kept RX/TX errors and drops at zero.
- Final deltas were `pppoe-wan2` RX/TX `281014677/22055780`, `pppoe-wancm`
  `122495967/56992574`, and `pppoe-wanct` `218902402/74692731` bytes. End filtered
  logread/dmesg had no FakeSIP/NFQUEUE/OOM/segfault/general-protection lines.
- Monitor log is local at
  `<local-artifact-dir>/audit-20260824-r19-candidate/monitor/fakesip-r19-45m-20260824-corrected.log`
  with SHA-256 `7b5b37887a8d591ecf93a23f080b5b2777ea4d097511ea59fe7317aa4b4ce32e`.
  The corrected candidate remains installed; no rollback was needed. The first parser-
  invalid attempt remains excluded and is recorded as F-030.

### Post-test Cleanup

- Removed the four known temporary candidate APKs from router `/tmp`; no known candidate
  temp files remain. A final FakeSIP-only read at `2026-08-24T10:05:52Z` still showed
  `running`, PID `17223`, unchanged command line and installed hashes, and queue 513
  registered to that PID. No other queue or service was touched.

### Snapshot Backup

- The current handoffs, Base64 copies, APK artifacts, rollback archive, and both monitor
  logs were archived locally at
  `<local-artifact-dir>/audit-20260824-r19-candidate/verification/fakesip-r19-install-test-20260824.tgz`
  and copied to Debian at `/root/fakesip-audit-20260824-r19-install-test-20260824.tgz`.

## 2026-09-02 Release Completion Addendum

- Functional source commit: `e9b87e0791b43f1d9677420649614a5116fd90e8`.
- Recipe provenance commit: `74838a41c8aed4dbeeaf98fe6382543f916ec645`.
- IPK privacy fixes: `53af722bc34e070dadc324fc1d72547dd5c01b8f` and
  `d3294825b52d8af11c6b30c7353f77336fe2b601`.
- Core and LuCI versions remain synchronized at `0.9.1-r19`. The core recipe pins the
  functional source commit above.
- The router still runs the exact OpenWrt 25 core binary SHA-256
  `1a5473a1a1f23efe97b7cb9d67208e8cc5a636edec2f23f8e87b57bf927876da`.
- A 60-second release check kept PID `2003`, RSS `896 kB`, VmSize `1148 kB`, one thread,
  and five descriptors stable. Queue 513 packet ID advanced `491217 -> 492359`; queue
  depth, kernel drop, and user drop remained zero. All three configured PPPoE devices
  retained zero RX/TX errors and drops.
- The PID change since the August window was explained by a logged normal exit followed
  by startup on 2026-09-01; no crash, OOM, segfault, or NFQUEUE kernel diagnostic was
  observed.
- Scope remained FakeSIP and queue 513 only. No other queue, service, route policy, or
  NAT configuration was read or changed.
