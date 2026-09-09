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

## 2026-09-05 Long-run Audit Resume

- The audit resumed from branch head `606aef130a957d020131699cb3ecd96d5370967d`.
- The working tree initially contained only the twelve pre-existing untracked 2026-08-18
  handoff Markdown/Base64 files; they remain outside the tracked release state.
- The first router read at `2026-09-05 09:06:27 GMT` reported OpenWrt 25.12.5 and init
  status `running`, but `pgrep -x fakesip` returned no exact-name PID. This unresolved
  discrepancy is recorded as F-050 and must be reconciled through procd, queue 513, full
  command-line, and `/proc` evidence before any source or router change.
- Current scope remains FakeSIP and queue 513 only. The audit must not read or modify any
  other NFQUEUE service, mwan policy, or NAT6 configuration.
- F-050 is resolved as a monitoring-tool false negative: procd, `ps`, queue 513, and
  `/proc/2432` all agree that FakeSIP is running. PID `2432` owns queue 513 with zero
  queue depth, kernel drop, and user drop; RSS is `900 kB`, VmSize `1148 kB`, RssAnon
  `168 kB`, with one thread and five descriptors. Exact-name `pgrep` is not used again.
- The optional `od` utility was absent during that diagnosis (F-051); no state changed.
- A 60-second sample kept PID `2432`, start ticks `64048480`, RSS `900 kB`, VmSize
  `1148 kB`, RssAnon `168 kB`, one thread, and five descriptors unchanged. Queue 513
  packet ID advanced `460623 -> 460750`; queue depth, kernel drop, and user drop stayed
  zero. All three PPPoE devices reported zero RX/TX errors and drops.
- Logread exposed a separate high-risk shutdown event: PID `32057` started at
  `2026-09-04 20:30:26 GMT`, did not stop on SIGTERM, and was SIGKILLed by procd five
  seconds later before PID `2432` started. This is F-052 and blocks the next release
  until the shutdown path is fixed and verified live.
- A subsequent source-read command missed `src/globvar.h`; the header actually resides at
  `include/globvar.h`. This read-path error is F-053 and does not alter F-052 evidence.
- The first isolated Debian shutdown reproducer was invalid because shell operator
  precedence backgrounded the build AND-list rather than a confirmed FakeSIP process.
  Its exit 143 is not product evidence; this is recorded as F-054 and must be rerun with
  synchronous build plus explicit PID/queue ownership checks.
- The corrected Debian r19 baseline used a confirmed FakeSIP PID and queue 6513 owner;
  idle SIGTERM exited normally with status 0 in about 103 ms. This proves F-052 is not a
  universal glibc failure but does not clear the observed OpenWrt/musl restart event.
- Gemini CLI 0.53.0 was asked to review the current shutdown/LuCI patch but Code Assist
  again rejected authorization with HTTP 403 before inference. This is F-055; no Gemini
  review result exists and no further retry is planned in this release cycle.
- A live LuCI screenshot baseline was attempted through a successful Debian HTTP tunnel,
  but the Browser runtime had no available browser. This is F-056. The tunnel was closed
  intentionally; visual verification must rely on DOM/classes, Node tests, and live asset
  loading unless a supported browser becomes available later.
- The first direct init-test invocation lacked an explicit shell and failed permission
  checking while later commands made the batch exit zero. This is F-057; no pass is
  claimed until a fail-fast `sh tests/test_openwrt_init.sh` run succeeds.
- A Debian verification transfer then misplaced `tests/test_nfqueue.c` under `src/`, and
  the production wildcard build failed with duplicate symbols. This is F-058, not a
  product regression; the exact disposable file must be removed before rerunning.
- The first clean-clone package build stopped before compilation because a script guessed
  the suffix of short SHA `6116df7` incorrectly. The actual full clone HEAD is
  `6116df735d7f7cf0d90c544bd31e5aab53cf393b`. This is F-059 and is a direct example of
  why all full identifiers must be read from Git rather than reconstructed from memory.
- Static review found that `tools/debian-smoke-test.sh` used only `set -u`, allowing a
  failed `run()` call to be masked by the final successful summary. The harness now uses
  `set -euo pipefail`; its full corrected run is required before release.
- The first r20 artifact extraction attempt omitted `--allow-untrusted`, so the SDK host
  `apk` rejected the intentionally unsigned local APK before content inspection. This is
  F-060. The metadata read was valid, but the incomplete extraction batch is discarded;
  a fresh fail-fast extraction with the explicit flag is required.
- The first pre-install router backup call never reached SSH because its JavaScript
  wrapper interpolated the remote `${TS}` shell variable and raised a local reference
  error. This is F-061; router state remained unchanged and a non-interpolating retry is
  required before installation.
- The first post-install APK file-hash comparison omitted creation of the exact apk-tools
  extraction subdirectories (F-062), and a separate router-loopback LuCI fetch was denied
  while its empty output was still hashed (F-063). Neither changed router state. Both
  results are discarded; corrected isolated checks must create destinations explicitly
  and fetch the LAN HTTP endpoint from Debian with nonempty-content validation.
- The first Debian LAN fetch then assumed port 80 on the SSH address and was refused
  (F-064). That endpoint guess is discarded; uHTTPd listener evidence must be read before
  the next live asset request.
- The first final local test batch called `tests/test_luci_fakesip.js` without its two
  required path arguments and stopped at the usage check (F-065). Fail-fast behavior was
  correct, but the entire batch must be rerun using the canonical tracked invocation.
- A local rollback-archive extraction command was rejected before execution because it
  used recursive `rm` for cleanup (F-066). The corrected check must map router-absolute
  manifest paths into a unique extraction directory and use scoped depth-first deletion.

## 2026-09-05 r20 Install And Release-Candidate State

- Clean OpenWrt 25 APK and OpenWrt 22.03 IPK builds completed from recipe head
  `6116df735d7f7cf0d90c544bd31e5aab53cf393b`, pinned to functional source
  `8f000525b1fa2711a2659810df397ebdcc21d7f7`.
- Artifact extraction verified synchronized `0.9.1-r20` versions, root ownership,
  expected modes and dependencies, neutral IPK `Source:` fields, and no private content.
- The pre-install backup SHA-256 is
  `c3345de7900fc79763bccf9f5e5d1f0f1e4e76ee7d16810e4b6eb1c43ee054da`.
  Router, local, and Debian copies match; local extraction and rollback syntax passed.
- The OpenWrt 25 upgrade preserved the UCI export exactly. Installed core, init, and LuCI
  hashes match their APK extraction. The service retained the formal IMS dual-URI,
  three-PPPoE, outbound IPv4/IPv6, silent, repeat 1, TTL 3 configuration.
- Twelve consecutive restarts replaced the process normally in 1.03-1.04 seconds each.
  Every old PID disappeared, every queue owner matched its process, drops stayed zero,
  and no procd SIGKILL occurred.
- The following 15-minute sample retained PID 15844, one thread, five descriptors, and
  VmSize 1148 kB; RSS settled at 924 kB. Queue packet ID advanced 270 to 3156 with zero
  depth, kernel drop, and user drop. No new severe runtime diagnostic appeared.
- The live LuCI JavaScript loaded successfully from Debian through the actual HTTP
  listener and matched the APK/live-file hash. Browser screenshot coverage remains
  unavailable under F-056 and is not claimed.
- Temporary router APKs, monitor copy, and the verified package-default `.apk-new` were
  removed. The service remained running and queue 513 remained healthy.
- The first tag-push batch created the correct local r20 annotated tag but stopped before
  pushing because its tagger assertion wrapped Git's already bracketed email in another
  pair of angle brackets. This is F-067. The remote tag remained absent; the existing
  local tag must be verified and pushed without recreation.
- The corrected tagger check passed and the existing annotated tag was pushed. GitHub
  release `v0.9.1-openwrt-r20` is published, non-draft, and non-prerelease. Its tag
  dereferences to `84092aeea6079ea0458ef482aaf154a4cbf0f1df`.
- All four remote package digests match local artifacts. A fresh download of the four
  packages plus `SHA256SUMS` passed checksum verification. r20 is therefore released;
  only post-publication handoff commit, default-branch integration, and branch inventory
  reporting remain.
- Pull request 7 was integrated without GitHub's server-generated merge identity. A
  local ordinary merge commit, `bc254fef86e485006ce8a883dbe9b1261f4e239d`, uses
  `Codex <codex@local.invalid>` for both author and committer and was pushed to `master`.
  GitHub reports the pull request merged at that commit.
- Branch inventory after the merge: `codex/fakesip-bug-findings` and
  `copilot/code-analysis-improvements` are fully contained by master. The
  `copilot/code-analysis-improvements-again` branch still has one unique historical
  commit. GitHub has no branch-hide operation. No remote branch was deleted because the
  user's word "hide" does not unambiguously authorize destructive deletion; the two
  fully contained branches are safe deletion candidates if explicitly approved.
- Final router snapshot at `2026-09-05T09:56:04Z` retained PID 15844, RSS 924 kB,
  VmSize 1148 kB, one thread, five descriptors, and queue row packet ID 4926 with zero
  depth/kernel/user drops. No post-monitor anomaly or known temporary r20 file remained.

## 2026-09-06 LuCI Dark-Mode Resume

- The user reported that the FakeSIP LuCI night mode is visibly defective.
- A live HTTP tunnel was established, but the Browser runtime had no available browser
  and could not open the page. This is F-068; the tunnel was closed and no router state
  changed.
- The current view adds no custom colors and relies on generic LuCI classes. The next
  step is to identify the router's active theme and inspect its exact dark-mode selectors
  before changing markup or CSS.
- Live Bootstrap CSS inspection found the concrete contrast defect: dark mode uses a
  near-black page background while `.ifacebadge-active` hard-codes a black border, and
  every service state otherwise shares nearly the same neutral badge. Positive/negative
  button colors also require the standard `important` modifier in this theme.
- The first combined source/test patch used one inexact array delimiter and was rejected
  atomically (F-069). No product file changed; smaller exact-context patches are next.
- The first Traditional Chinese completeness test reused JSON decoding for JavaScript
  single-quoted strings and failed on the legal embedded `"sip:"` text (F-070). This is
  a test-parser defect, not a PO verdict; separate syntax-aware decoders are required.
- The first replacement JavaScript decoder accidentally returned the literal source
  fragment `" + value + "` for every message (F-071). The test batch stopped before any
  package or router operation; correct concatenation and a full clean rerun are required.
- The next quote correction left one escape layer in the JavaScript file and failed its
  syntax check before execution (F-072). Product files and router state remain unchanged;
  use a double-quoted outer function-source string and restart all gates.
- The first combined localization/docs patch was atomically rejected because one
  OpenWrt README paragraph had different line wrapping (F-073). No document content was
  partially changed; continue with small exact-context patches.
- A subsequent full README replacement was rejected because one patch attempted both
  delete and add operations on the same path (F-074). No README changed; perform those
  operations separately.
- The next OpenWrt docs attempt mistakenly retained the same wrapping assumption and was
  rejected again (F-075). Numbered lines now provide exact small-hunk anchors; do not
  bundle the new translated guide with those existing-file edits.
- A direct Gemini review attempt again failed at Code Assist onboarding with an invalid
  product license (HTTP 403), and the CLI also reported missing workspace trust (F-076).
  It changed nothing and provides no review verdict; do not retry or claim approval.
- The first pre-r21 router snapshot reached Debian but its nested `natter-openwrt` alias
  did not resolve (F-077). No router command ran; use the explicit authorized router
  address and port after checking jump-host SSH tooling.
- The first r21 push used `origin`, which currently points to the read-only upstream, and
  GitHub rejected it with HTTP 403 (F-078). The local commits are intact; identify the
  authorized fork remote, push there, and verify its exact ref before SDK build.
- The optional standard SDK recipe check reused a stateful `.config` and expanded into a
  full unrelated kernel package build, so it was interrupted and is not a valid verdict
  (F-079). Direct r21 APK construction and artifact inspection passed; clean only the two
  added recipe directories and prove the LMO on the router instead.
- The r21 APK upgrade itself succeeded and preserved UCI, but BusyBox find rejected the
  unsupported LuCI-cache `-delete` action; fail-fast stopped before FakeSIP restart
  (F-080). Recover immediately with `-exec rm -f`, start only FakeSIP, and rerun every
  post-install check.
- The post-install 60-second monitor emitted its start snapshot, but the context
  transition closed the execution session before its final output could be retrieved
  (F-081). Avoid repeating the wait; compare one current snapshot with PID 29708 and
  queue packet ID 210, both already captured with zero drops.
- The first follow-up snapshot was blocked locally by a temporary restricted network
  sandbox before reaching Debian (F-082). No remote state changed; retry exactly once
  now that the user restored full access.
- The first combined r21 release/handoff patch ended with an empty update hunk and was
  atomically rejected (F-083). No release file or addendum changed; split the operation
  and read privacy/artifact tails before patching them.
- The next addendum batch used the wrong capitalization for the privacy document's final
  `pull request` line and was atomically rejected (F-084). Append each document using its
  exact final paragraph.
- The privacy-only retry also missed that `Pull request` is split across two physical
  lines and was rejected (F-085). Exact numbered and byte output is now available.

## 2026-09-06 r21 Installed Candidate State

- Functional commit: `bbcc1bf0d2981d64d90f69b264424d1a7ef18a41`.
- Synchronized r21 recipe commit: `d00c95cb8ef89be9aa31c7ae27f77e29e5db57af`.
- Debian full Linux regression and direct OpenWrt 25 APK build passed.
- Candidate APK SHA-256 values are `7d343329...f004` for core and
  `6b5ccdbc...e069` for LuCI. No r21 IPK was built or will be published.
- Router UCI SHA remained `39ab69d...6fbc`; installed file hashes match extraction.
- LuCI `zh_tw` loaded the embedded catalog and returned the expected Traditional Chinese
  strings. Browser screenshot coverage remains unavailable and is not claimed.
- After nearly six hours, PID 29708 remained stable, queue packet ID reached 259760, and
  depth/kernel/user drops remained zero. RSS was 852 kB with one thread and five FDs.
- Temporary r21 APKs and `/etc/config/fakesip.apk-new` were removed. The private rollback
  archive exists in three verified locations with SHA-256 `91b43d...16a3`.

## 2026-09-06 r21 Final Publication

- Annotated tag `v0.9.1-openwrt-r21` points to commit
  `36650e6b636806ed00458b9593adbd29ca24ae05`.
- The public release is `https://github.com/alzpqm/FakeSIP/releases/tag/v0.9.1-openwrt-r21`.
- The release contains exactly the two OpenWrt 25+ APKs and `SHA256SUMS`; no IPK or
  private backup is present.
- A fresh GitHub download passed `shasum -a 256 -c SHA256SUMS` for both APKs.
- Older release pages and their historical assets were intentionally left unchanged;
  they are unsupported, and users of older OpenWrt versions must build from source.

## 2026-09-09 FakeHTTP Candidate Coordination Window

- FakeHTTP requested a short A/B/A test window for two user-supplied cloud-storage
  hostname candidates.
- From the acknowledgement onward, FakeSIP/queue513 is reserved in its formal state for
  at least 20 minutes: no restart, stop, configuration change, or new routing mark.
- No queue512/FakeHTTP state will be read or modified from this workspace.
- The cross-thread reply tool was approval-blocked before execution and is recorded as
  F-088; the current-thread acknowledgement is the operative coordination record.
- FakeHTTP's first source-bound curl matrix was invalidated because packet capture showed
  transparent-proxy routing sent all three nominal sources through wan2. That data must
  not be used. FakeHTTP restored its state and began a narrower check for destination
  `120.46.63.139:443` using temporary source ports 43000-43099 to bypass the proxy and
  verify each egress with packet capture before A/B. FakeSIP/queue513 remains unchanged
  for this additional window.

## 2026-09-09 FakeHTTP Candidate Result

- The valid direct window ran from 00:41:27 to 00:48:40 Asia/Taipei and used 45 fixed-IP
  32 MiB transfers to `120.46.63.139`; 30 completed and 15 timed out, including 14 on
  wanct and one on wancm.
- Against bracketing controls, wan2 measured -0.71% for the China Mobile candidate and
  +1.73% for the China Telecom candidate. Wancm measured +9.05% and -15.05%, while both
  wanct candidates completed 0/3 runs. The candidates were rejected because they did not
  improve consistently across the three links.
- FakeHTTP restored its byte-identical formal configuration with silent mode enabled;
  its temporary source routes and two test-return rules were removed. Its later health
  check reported PID 31540 and queue512 with zero drops.
- FakeHTTP did not read or modify queue513. The FakeSIP stability reservation is now
  released, and none of these FakeHTTP candidates changes the r21 FakeSIP release.

## 2026-09-09 Gemini CLI Authentication Audit

- The installed official `@google/gemini-cli` was upgraded successfully from 0.53.0 to
  npm stable 0.59.0.
- The cached auth type was `oauth-personal`; a clean retry without the historical Cloud
  Project variable failed as `UNSUPPORTED_CLIENT` because Google retired Gemini Code
  Assist for individual free-tier use in this client. See F-089.
- No `GEMINI_API_KEY`, `GOOGLE_API_KEY`, gcloud installation, ADC file, or Gemini `.env`
  was present. The shell profile still owns a historical Cloud Project export and was
  deliberately not edited because other Google Cloud workflows may depend on it.
- The CLI user setting was changed to `gemini-api-key`, preventing future calls from
  silently retrying the dead OAuth route. A new AI Studio Auth key is still required.
- As of September 2026, new AI Studio keys are service-account-bound Auth keys; old
  unrestricted Standard keys are rejected and Standard-key support is being removed.
  The key must never be committed to this repository or passed in a visible command-line
  argument.
- A local `gemini-authkey` launcher was installed in `~/.local/bin` with mode 0700 and
  added to the Bash login PATH. It stores a user-entered key in macOS Keychain, retrieves
  it only into the child process environment, and locally unsets Code Assist/Vertex
  variables before starting Gemini CLI. Its shell syntax and help path passed; no key
  has been created or stored yet.
