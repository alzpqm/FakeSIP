# FakeSIP 2026-08-24 Bug Audit Findings Handoff

Date: 2026-08-24 (Asia/Taipei)
Repository: `<local-fakesip-worktree>`
Branch: `codex/fakesip-bug-findings`
Base HEAD: `32cc1c17f63aac9f9d2933d57e75baf18d23f66b`
Status: dirty r19 candidate installed and 45-minute tested, not released

## Scope and Safety Boundary

This audit covered FakeSIP core, queue 513 integration, the OpenWrt init script,
LuCI package metadata, direct IPK/APK builders, and focused tests. It did not read or
modify FakeHTTP, queue 512, mwan policy, or NAT6. The live router received authorized
FakeSIP-only package/service changes and queue513-only monitoring; no other service or
queue was read or modified.

No commit, push, tag, pull-request update, GitHub release, or cloud upload occurred.

## Confirmed Fixes

### 1. SIP IMS host classification

The old substring test classified lookalike domains and query text as IMS. The new parser
matches only the two exact observed carrier hosts or a proper `.3gppnetwork.org` suffix,
with case-insensitive host matching and correct port/parameter/query/trailing-dot
boundaries.

Files:

- `src/payload.c`
- `tests/test_payload.c`

### 2. Raw socket over-provisioning

`fs_rawsend_setup()` opened all three socket families regardless of selected mode. It now
opens AF_PACKET only for outbound fake packets and raw IPv4/IPv6 sockets only for enabled
inbound families. Cleanup clears cached bind indices.

Files:

- `src/rawsend.c`
- `tests/test_rawsend.c`

### 3. NFQUEUE hardware-address length

The callback previously forced an eight-byte link-layer address. It now converts
`hw_addrlen` from network byte order, bounds it to `sockaddr_ll.sll_addr`, preserves the
real length, clears stale bytes, and handles NULL PPP/postrouting hardware addresses.

Files:

- `src/nfqueue.c`
- `tests/test_nfqueue.c`

### 4. Logger failure handling

The logger now checks `localtime_r()` and `strftime()`, uses a deterministic fallback
timestamp, and falls back to `stderr` when `g_ctx.logfp` is NULL.

Files:

- `src/logging.c`
- `tests/test_logging.c`

### 5. Unknown OpenWrt SIP profile

An unknown profile could log an error but still start with the program's standard
payload. The init script now rejects unknown values before opening a procd instance.

Files:

- `openwrt/fakesip/files/fakesip.init`
- `tests/test_openwrt_init.sh`

### 6. Cross-version config permissions

The direct APK builder installed `/etc/config/fakesip` as 0644, unlike IPK and the live
router. It now records mode 0600.

Files:

- `tools/build-openwrt-apk.sh`
- `tools/openwrt-package-smoke-test.sh`

### 7. LuCI package architecture

Top-level `PKGARCH:=all` is retained for the IPK feed package, but OpenWrt 25 APK images
may omit `all` from `/etc/apk/arch`. The first direct APK builder used `arch: all` for
LuCI and was rejected by the real router. The builder now validates the Makefile field
but emits the target `ARCH` for both direct APKs; the corrected x86_64 pair installed
successfully.

Files:

- `openwrt/luci-app-fakesip/Makefile`
- `tools/build-openwrt-apk.sh`
- `tools/openwrt-package-smoke-test.sh`

## Preserved r19 Experimental Work

- Profile: `china_sip_observed`
- Rotation order:
  1. `sip:user@sipcq16.xnq.r.10086.cn:5260`
  2. `sip:user@sipsc109.r01.rcs.189.cn:5260`
- Default profile remains `china_all`.
- The observed profile is experimental. Household DNS/connection observations do not
  prove a carrier QoS whitelist or guaranteed rate-limit bypass.
- Existing source order is covered by first/second/third/first and two-host regressions.

## Verification Results

Passed locally:

- core regression with explicit macOS CLI skip
- OpenWrt init behavior tests
- LuCI behavior, JavaScript, and JSON checks
- OpenWrt package smoke test
- shell syntax and `git diff --check`

Passed on Debian 13.6 using source hashes identical to the Mac:

- debug build and full CLI/core regression
- ASan, LSan, and UBSan unit suite
- GCC `-fanalyzer` build without analyzer warnings
- Debian namespace smoke test
- Linux nft partial-setup rollback test
- outbound dual-family and inbound IPv4-only raw-socket runtime modes

The Debian iptables rollback integration did not run because the shared host lacks
`iptables` and `ip6tables`. This remains a documented coverage gap.

Passed package builds and inspections:

- OpenWrt 22.03.7 x86/64 IPK build
- OpenWrt 25.12.5 x86/64 APK build
- package integrity and dependency metadata
- IPK core x86_64 and LuCI all architecture
- direct APK core and LuCI x86_64 architecture
- archive/metadata/extracted root ownership
- mode 0600 config and mode 0755 init/binary
- source-file identity and expected packaged binary markers

LocalAI runtimes were unavailable. Gemini Code Assist rejected the current Workspace
authorization. No model output is claimed as audit evidence.

## Candidate Artifacts

```text
646079ff637a90ae3b171450e6f1d73a12d3365457010fb435e5c042a4742f2c  fakesip_0.9.1-19_x86_64.ipk
49595cf533d75b741b4f2ab521b6ca9927cbbc217f893aaa215d45150abb985b  luci-app-fakesip_0.9.1-19_all.ipk
62b48d096c056169bbce945a7043c60020b125b3e6f2b5b9972725ff0097dfd9  rejected-arch-all-fakesip-0.9.1-r19.apk
6a923dfdb7d97e515adc9c902ffc5dea4f0f72e9f231ce4a25776d90c24b1df5  rejected-arch-all-luci-app-fakesip-0.9.1-r19.apk
ae9ccb82225e093dc415b80e3a015a3355004b0d47e4cf72e9e58d7655322713  fakesip-0.9.1-r19-targetarch.apk
2541c05fd04ccd1086e1379272a45b8d5da68a18b5296b2c36f033f55e18a8c9  luci-app-fakesip-0.9.1-r19-targetarch.apk
3194a589a6d7fd1ae1f11e85fbfbedc7243461b94754b852ff9a8809187e442e  fakesip-audit-20260824-candidate-artifacts.tgz
0580d35b104dd1205321200f88ea8fdd69e87de77411b90a7d94fe729db34919  fakesip-audit-20260824-source-and-handoffs.tgz
```

Debian paths:

- `/root/fakesip-audit-20260824-ipk22-fixed`
- `/root/fakesip-audit-20260824-apk25-fixed`
- `/root/fakesip-audit-20260824-candidate-artifacts.tgz`
- `/root/fakesip-audit-20260824-source-and-handoffs.tgz`

Mac path:

- `<local-artifact-dir>/audit-20260824-r19-candidate`

The accidental apk extraction under Debian `/root` was archived, then every exact
package-listed misplaced path was removed. Recovery archive SHA-256:

```text
18dbd10bd7770dbf019d57e41834a064bda2f6858a5d229840ac473575e639be
```

## Live Router State

The corrected target-architecture candidate is installed and remains active after the
45-minute queue513-only window:

- PID 17223
- queue 513
- outbound IPv4 and IPv6
- silent mode, repeat 1, TTL 3
- both observed SIP URIs
- `pppoe-wan2`, `pppoe-wancm`, and `pppoe-wanct`

Final post-window read-only sample:

- queue sequence 3021 to 18006 during 2700 seconds
- backlog 0, kernel drop 0, user drop 0
- RSS 904 kB, VmSize 1148 kB, one thread, five descriptors
- 39 CPU tick increase
- all three PPP interfaces: RX/TX errors and drops all zero

The complete local monitor log is
`<local-artifact-dir>/audit-20260824-r19-candidate/monitor/fakesip-r19-45m-20260824-corrected.log`
with SHA-256
`7b5b37887a8d591ecf93a23f080b5b2777ea4d097511ea59fe7317aa4b4ce32e`.

## Release Blocker and Next Action

`openwrt/fakesip/Makefile` still pins source revision
`ebe90f7fb191e0fc292006b0da3f28c5ef4a8da5`, while this fix set is uncommitted. The
direct builders used the dirty worktree; a normal fetched-source build would differ.

Before formal release:

1. Review the complete dirty diff and preserve unrelated user work.
2. Commit with the configured nonpersonal author identity.
3. Push the commit and update `PKG_SOURCE_VERSION` to the reachable revision.
4. Synchronize both package releases to the next release number.
5. Rebuild both IPK and APK formats from the pinned source.
6. Rebuild from the pinned source, repeat package inspection, and run the release
   verification on a clean target. The current dirty-worktree install is test evidence,
   not provenance evidence.

Do not describe the present r19 candidates as a formal release.

## 2026-09-02 Release Resolution

The earlier provenance blocker is resolved. The functional source was committed
anonymously, the OpenWrt recipe was pinned to that reachable commit, and the branch was
pushed to the public fork. Clean Debian tests passed for debug build, full CLI/core,
ASan/LSan/UBSan, GCC analyzer, Debian smoke, nft syntax, and nft rollback.

The final OpenWrt 25 APK pair and OpenWrt 22.03 IPK pair both use release `0.9.1-r19`.
Artifact inspection verified versions, dependencies, architecture, root ownership, file
modes, and payload identity. The first IPKs exposed an absolute Debian `Source:` path;
they were rejected. The helper now copies package recipes into the SDK and explicitly
cleans both package targets. Final IPKs report only `Source: package/fakesip` and
`Source: package/luci-app-fakesip`.

Gemini CLI did not review the release because Code Assist authorization returned HTTP
403 before inference. No Gemini approval is claimed. Executable tests and direct source,
package, and runtime evidence are the release basis.

## 2026-09-05 Long-run Finding

### High: FakeSIP did not stop within the procd SIGTERM window

Router logread contains a concrete event where PID 32057 started normally, received a
service stop, and remained alive until procd sent SIGKILL five seconds later. The next
instance, PID 2432, is healthy and queue 513 currently has zero depth and drops, so this
is a shutdown-path defect rather than an active forwarding outage.

The next release is blocked until signal handling and the NFQUEUE receive loop are
reviewed, a deterministic Linux/OpenWrt stop test is added, and live restart evidence
shows a normal exit without procd SIGKILL.

### Medium: Debian smoke failures could be hidden by the final summary

`tools/debian-smoke-test.sh` used only `set -u`. Its `run()` helper preserved the tested
command's exit status, but callers did not check that status, so a failed build, core
test, or nft syntax check could be followed by a successful final summary and make the
whole script exit zero. The next release changes the harness to `set -euo pipefail` and
must rerun the complete smoke suite to prove the stricter gate is usable.

## 2026-09-05 r20 Resolution

No catastrophic or unresolved high-severity defect remains in the r20 candidate.

The shutdown finding is resolved by making the NFQUEUE descriptor nonblocking, polling
it with a bounded 250 ms wait, and checking the signal exit flag around every wait and
receive. The OpenWrt service also declares a 15-second procd termination timeout. A new
unit regression proves an idle SA_RESTART signal cannot trap the loop indefinitely.
Debian terminated a confirmed isolated queue owner normally in about 103 ms. The live
OpenWrt 25 installation then completed 12 consecutive service restarts: every previous
PID logged `exiting normally`, disappeared before replacement, and was replaced in
1.03-1.04 seconds. No procd SIGKILL appeared.

The smoke-harness finding is resolved by `set -euo pipefail`. The corrected full Debian
smoke, sanitizer/core suite, analyzer, nft rollback integration, OpenWrt init/LuCI tests,
and both package-format builds passed.

The final 15-minute OpenWrt sample kept one PID, one thread, five descriptors, and
VmSize 1148 kB. RSS settled at 924 kB. Queue 513 packet ID advanced from 270 to 3156;
all 16 samples had depth, kernel drop, and user drop equal to zero. One PPPoE interface
had a pre-window cumulative RX drop of one, but it did not increase. No new OOM,
segfault, NFQUEUE failure, verdict failure, or forced termination was observed.

## 2026-09-06 r21 Findings

No catastrophic or high-severity runtime defect was found before r21.

The LuCI night-mode defect was concrete: Bootstrap dark mode uses a near-black page
background while `ifacebadge-active` retains a black border, making service states hard
to distinguish. Status now uses Bootstrap's theme-aware `label success`, `label warning`,
and `label notice` classes. Start and Stop use the `important` modifier for filled
positive/negative contrast. Static behavior tests forbid the old active badge.

All 76 LuCI messages have nonempty Traditional Chinese translations with matching format
placeholders. The LuCI APK embeds `fakesip.zh-tw.lmo`; the installed router's LuCI i18n
loader returned the expected translations for Running, Working, and OpenWrt network
selection under `zh_tw`.

Linux sanitizer/CLI regression, OpenWrt init/LuCI/package smoke, direct OpenWrt 25 APK
build, APK metadata/content/ownership inspection, and live installation passed. The
optional normal recipe check was invalid because a stateful SDK config expanded into an
unrelated full kernel package build; it was interrupted and recorded as F-079, not
counted as evidence. No IPK was built for r21 by policy.
