# FakeSIP Bug Audit Failure Log - 2026-08-24

## Recording Policy

This file records every observed nonzero command, timeout, missing dependency,
connection failure, test-harness mistake, incomplete rollback, and verification gap for
the 2026-08-24 audit. Expected negative-test diagnostics are listed separately and are
not mislabeled as product failures.

## F-001: Historical APK Extraction Harness Setup Failure

- Date observed: 2026-08-18
- Scope: local verification of the experimental `0.9.1-r19` APK artifacts
- Result: failed on the first attempt
- Diagnostics included:
  - `Error opening destination .../core: No such file or directory`
  - `Error opening destination .../luci: No such file or directory`
  - dependent `strings`, `grep`, and `stat` checks then reported missing files
- Cause: the extraction destination directories had not been created.
- Correction: created both directories with `mkdir -p` and repeated the extraction and
  metadata checks.
- Corrected result: passed, including APK contents, metadata, and root ownership.
- Classification: test-harness setup failure, not an APK defect.

## F-002: Debian iptables Rollback Integration Could Not Run

- Date observed: 2026-08-24
- Host: Debian 13.6 jump host, kernel 6.12.96
- Command: `tools/linux-nfrules-rollback-test.sh iptables`
- Exit code: 1
- Exact output: `FAIL: iptables is unavailable`
- Cause: neither `iptables` nor `ip6tables` is installed on the Debian host.
- Product impact: none demonstrated.
- Coverage impact: the current source's real iptables/ip6tables partial-setup rollback
  path was not dynamically verified in this audit on Debian.
- Related evidence: `tools/linux-nfrules-rollback-test.sh nft` passed in an isolated
  network namespace on the same host. Existing mocked unit tests also cover both
  iptables setup failure branches, but they do not replace a real integration test.
- Correction status: open. Do not install packages on the shared Debian host merely to
  make this test green without a separate need or user request.

## F-003: LocalAI Status Check Could Not Reach Ollama

- Date observed: 2026-08-24
- Command: `./bin/ai-team status`
- Working directory: `<local-ai-worktree>`
- Exit code: 7
- Endpoint: `http://127.0.0.1:11434`
- Exact diagnostic: `curl: (7) Failed to connect to 127.0.0.1 port 11434`
- Cause at time of recording: no process was listening on the configured Ollama port.
  The LaunchAgent state had not yet been inspected.
- Product impact: none. No FakeSIP code or runtime state was changed.
- Audit impact: the requested local-model review had not yet run. A later retry may be
  attempted after checking the existing service configuration; any retry result must be
  appended here.

Follow-up evidence:

- `launchctl print gui/501/local.ai-team.ollama` exited 113 and reported that the service
  could not be found.
- No matching LaunchAgent file, real `ollama` executable, Homebrew Ollama installation,
  or LM Studio application was found. The only `ollama` filename found was the LocalAI
  project's test double under `tests/fakebin` and must not be used as a real model.
- Classification: the LocalAI documentation remains in the workspace, but its documented
  local runtimes are not deployed in the current macOS environment. This is an
  environment/deployment mismatch, not a FakeSIP failure.

## F-004: Gemini Workspace Authorization Was Rejected

- Date observed: 2026-08-24
- Command path: `./bin/ai-team research` with temporary
  a temporary authorized Google Cloud project environment variable
- Prompt scope: public Linux, Netfilter, SIP, and SDP standards only; no credentials,
  router state, or uncommitted source was sent.
- Exit code: 1
- HTTP result: 403 Forbidden from the Google Code Assist onboarding route.
- Primary diagnostic: `You do not have a valid license of this product` with error
  identifier `#3501`.
- Product impact: none. No FakeSIP file or device state was changed.
- Audit impact: no Gemini response was produced and no model opinion can be cited for
  this audit.
- Classification: external authorization failure. Earlier historical authorization
  success is not evidence of current availability.

## F-005: First Router Read-Only SSH Command Had a Local Quoting Error

- Date observed: 2026-08-24
- Intended scope: read-only FakeSIP and queue 513 health collection through Debian
- Exit code: 2
- Diagnostic: local Bash reported `syntax error near unexpected token '}'` while parsing
  the nested SSH command.
- Device impact: none. The local shell rejected the command before SSH connected to the
  router, so no router command ran.
- Cause: overly nested local, Debian, and router quote layers around a grouped shell
  command.
- Correction: use an SSH `ProxyCommand` with one router-side command layer instead of a
  quoted nested SSH command. The corrected attempt and its result must be recorded in the
  final findings handoff.

## F-006: First Multi-File Source Patch Was Rejected

- Date observed: 2026-08-24
- Tool: `apply_patch`
- Result: failed before changing files
- Diagnostic: the expected blank-line context before `callback()` in `src/nfqueue.c`
  did not match the file exactly.
- Cause: one large patch used an overly specific whitespace context across four source
  files.
- Repository impact: none from this attempt. `apply_patch` rejected the patch atomically.
- Correction: split the change into small per-file patches and inspect each resulting
  diff before running tests.

## F-007: First Raw-Socket Test Patch Was Rejected

- Date observed: 2026-08-24
- Tool: `apply_patch`
- Target: `tests/test_rawsend.c`
- Result: failed before changing the target file
- Diagnostic: the expected context around `return sendto_result;` and the following
  function did not match the file's exact blank-line layout.
- Cause: the test patch was still too large and coupled several insertion points.
- Repository impact: none from this attempt.
- Correction: patch declarations, mocks, test helper, and `main()` call as independent
  edits with exact local context.

## F-008: Unfiltered ShellCheck Audit Exited Nonzero

- Date observed: 2026-08-24
- Host: Debian 13.6
- Scope: OpenWrt init, build/test helpers, and package smoke scripts
- Exit code: 1
- Result: ShellCheck reported existing warnings and informational findings.
- Main categories and disposition:
  - OpenWrt `rc.common` variables and BusyBox `ash` `local` declarations were reported as
    unused or non-POSIX. They are required framework or target-shell conventions.
  - Intentional compiler flag splitting through `$CFLAGS` was reported as SC2086.
    Quoting it as one argument would break the test compiler invocation.
  - Single-quoted test and grep programs were reported as SC2016 even though literal
    dollar signs are intended.
  - Dynamic mock variables in `tests/test_openwrt_init.sh` were reported as unused or
    unassigned because ShellCheck cannot follow the test's indirect expansion.
  - `destination` in `copy_latest_ipk()` is genuinely unused, but has no behavioral
    effect and predates this audit.
- Product impact: no reproducible FakeSIP defect was established from this run.
- Coverage status: ShellCheck did run across all named files, but the aggregate command
  is not a clean gate without project-specific exclusions or annotations.

## Expected Fault-Injection Diagnostics, Not Failures

The following messages appeared while successful core regression suites deliberately
exercised failure paths. The suites exited zero and asserted the expected behavior:

- invalid overlength SIP URI
- invalid srcinfo cache state or argument
- `write(): Broken pipe`
- injected failures from IPv4/IPv6 nft setup
- injected failures from IPv4/IPv6 iptables setup
- raw `sendto(): Operation not permitted`

These diagnostics prove that negative paths were executed. They are not runtime
incidents and must not be counted as failed tests.

## F-009: First OpenWrt 25.12 Build Launch Could Not Authenticate to Debian

- Date observed: 2026-08-24
- Intended host: Debian jump host `<debian-jump-host>`
- Intended action: start the local-source OpenWrt 25.12 APK builder
- Exit code: 255
- Diagnostic: `Permission denied (publickey,password)`.
- Cause: this attempt forced `BatchMode=yes`, but the jump host did not accept an
  available public key and interactive password authentication was disabled.
- Remote impact: none. SSH authentication failed before the remote build command ran.
- Product classification: connection-method failure, not a source or package build
  failure.
- Correction pending: recover the previously verified Debian login method from local
  configuration or handoff evidence, then rerun the same builder without exposing
  credentials in a handoff or final report.

## F-010: First Combined Artifact Inspection Assumed an ar-Format IPK

- Date observed: 2026-08-24
- Host: Debian jump host
- Scope: inspect the newly built OpenWrt 22.03 IPKs and 25.12 APKs
- Exit code: 1
- Diagnostic: GNU `ar` reported `file format not recognized` for
  `fakesip_0.9.1-19_x86_64.ipk`.
- Cause: the inspection harness assumed every IPK used the Debian ar container format.
  This SDK output must be identified before selecting its extraction method.
- Coverage impact: package SHA-256 values were printed, but the command stopped at the
  first IPK before content, ownership, or APK assertions ran. None of those assertions
  may be reported as passed from this attempt.
- Product impact: no package defect established. The failure occurred in the inspection
  harness and did not alter source, packages, SDK state, or either device.
- Correction pending: identify the container with `file` and signature bytes, then rerun
  all artifact assertions using the matching extractor.

## F-011: Second Artifact Inspection Had an Unnamed Content Assertion Failure

- Date observed: 2026-08-24
- Host: Debian jump host
- Scope: corrected double-tar IPK inspection plus APK inspection
- Exit code: 1
- Progress before failure:
  - both IPK control records reported version `0.9.1-19`;
  - both IPK data archives reported numeric ownership `0/0`;
  - both APK metadata records reported version `0.9.1-r19`, expected dependencies,
    and root ownership;
  - all four packages were extracted.
- Failure point: the script printed `CONTENT_ASSERTIONS` and then exited without a
  diagnostic because a bare command under `set -e` returned nonzero.
- Cause status: undetermined at the time of recording. The harness did not label each
  assertion, so neither a content mismatch nor an assertion-path mistake can be claimed
  yet.
- Coverage impact: metadata and archive ownership evidence above is valid, but content,
  source-byte comparison, extracted ownership, and mode checks remain incomplete.
- Correction pending: rerun each content assertion with a stable name and explicit
  pass/fail output, then fix the harness or product according to the first failing check.

## F-012: Named Artifact Diagnostics Exposed Three Harness Assumptions

- Date observed: 2026-08-24
- Host: Debian jump host
- Exit code: 1, intentionally returned after collecting every named assertion result
- Confirmed passes before classification:
  - the IPK core binary exists and is executable;
  - the IPK init script passes shell syntax;
  - the observed profile case exists;
  - both observed SIP hostnames exist in the packaged binary;
  - packaged IPK init and config files are byte-identical to the audited source;
  - the packaged IPK LuCI file exists and is byte-identical to the audited source.
- Failed diagnostic assumptions:
  - the harness searched for the exact text `Unknown SIP profile`, but the product uses a
    different diagnostic spelling or capitalization;
  - the harness assumed `apk extract -p DIR` placed package paths directly under `DIR`,
    but no files existed at the assumed `DIR/etc` and `DIR/www` paths;
  - the Debian host has no `node` executable, so Debian-side LuCI syntax checks returned
    127;
  - the harness searched for one exact LuCI expression rather than the stable profile
    identifier, so that assertion was too implementation-specific.
- Product classification: no new defect established. Source equality makes the missing
  Debian Node runtime irrelevant to package/source identity, and LuCI syntax had already
  passed on macOS.
- Correction pending: inspect the actual extraction tree and init text, use stable
  content identifiers, and keep the JavaScript syntax gate on the host where Node is
  present.

## F-013: apk extract Used the Database Root Instead of an Output Destination

- Date observed: 2026-08-24
- Host: Debian jump host
- Command mistake: `apk extract --allow-untrusted -p DIR PACKAGE`
- Cause: apk-tools 3 defines `-p` as the managed filesystem root. The extraction applet
  requires `--destination PATH` for an output directory.
- Side effect: package payload files were extracted under Debian's `/root` working tree,
  including paths below `/root/etc`, `/root/usr`, `/root/lib`, and `/root/www`.
- Safety boundary: this did not write Debian system `/etc` or `/usr`, did not contact the
  router, and did not modify FakeSIP queue 513. Some `/root/www` content had an older
  source timestamp, so prior scratch extraction may already have existed there.
- Recovery plan: archive the exact package-listed paths into the audit verification
  directory, remove only those exact files, and prune only directories proven empty with
  `rmdir`. Do not recursively delete any shared `/root` directory.
- Verification plan: confirm each package-listed misplaced file is absent after cleanup,
  retain the recovery archive and its SHA-256, then re-extract using
  `--destination PATH`.

## F-014: SDK Architecture Diagnostic Used an Unsafe printf Format

- Date observed: 2026-08-24
- Host: Debian jump host
- Scope: read-only search of OpenWrt 22.03 package architecture rules
- Diagnostic: Bash `printf` reported `invalid option` for a format string beginning
  with `---`.
- Cause: the command used `printf "--- %s\\n"` without the portable `printf '%s\\n'`
  form or a leading `--` supported by that implementation.
- Impact: section labels for sample Makefiles were not printed. The surrounding grep and
  package-default source reads continued, no files were changed, and the command's final
  pipeline exited zero.
- Correction: avoid option-like format strings. This output-format failure does not
  affect the confirmed `Package/Default` architecture control-flow evidence.

## F-015: First APK Architecture Patch Changed the Wrong Repeated Field

- Date observed: 2026-08-24
- Scope: local uncommitted edit to `tools/build-openwrt-apk.sh`
- Cause: a patch against two structurally identical `--info "arch:$ARCH"` lines matched
  the first occurrence. It temporarily assigned the LuCI `all` architecture to the core
  package while leaving the LuCI package target-specific.
- Detection: immediate numbered source and diff inspection before running any test or
  builder.
- Artifact and device impact: none. No package was built, copied, or installed from the
  transient state.
- Correction: restore core metadata to `$ARCH`, assign only LuCI metadata to
  `$LUCI_ARCH`, and add smoke assertions requiring both intended fields.

## F-016: Final Verification Command Was Rejected by the JavaScript Wrapper

- Date observed: 2026-08-24
- Intended host: Debian jump host
- Result: tool script parse failure before `exec_command` was called
- Diagnostic: `SyntaxError: Unexpected token '%'`.
- Cause: shell parameter expansions `${pair%%:*}` and `${pair#*:}` appeared inside a
  JavaScript template literal and were parsed as JavaScript interpolation syntax.
- Remote, repository, and device impact: none. The wrapper failed before launching SSH.
- Correction: escape the two shell `${...}` expressions in the JavaScript literal and
  rerun the complete verification command from the beginning.

## F-017: GCC 14 APK Binary Did Not Preserve a Logging Literal for strings

- Date observed: 2026-08-24
- Host: Debian jump host
- Scope: final fixed-package content assertions
- Exit code: 1
- Assertion: require the exact line `time unavailable` in `strings` output from both
  stripped cross-compiled binaries.
- Result: the OpenWrt 22.03/GCC 11 IPK binary passed; the OpenWrt 25.12/GCC 14/O3 APK
  binary did not expose that exact contiguous string.
- Evidence already passed before this point: both IPK and APK package integrity,
  versions, expected core/LuCI architectures, archive/metadata root ownership, APK
  config mode 0600, source-identical init/config files, observed hostnames, and the
  hardware-address guard string.
- Cause status: under investigation. An optimizing compiler may materialize the short
  fallback text without retaining a printable literal, so `strings` is not by itself a
  valid control-flow test.
- Product status: do not infer that the logging fix is absent. Compare audited source
  hashes, build provenance, and the focused native logging regression before deciding.
- Correction pending: replace optimizer-sensitive binary-literal assertions with stable
  source/build identity evidence and rerun all remaining checks.

## F-018: IPK Binary Was Compared with the Pre-rstrip pkgdir Copy

- Date observed: 2026-08-24
- Host: Debian jump host
- Scope: final fixed-package verification after correcting the logging string check
- Exit code: 1
- Failed assertion: compare the extracted IPK binary with
  `.pkgdir/fakesip/usr/bin/fakesip` in the OpenWrt 22.03 SDK build tree.
- Diagnostic: `cmp` reported a difference beginning at ELF byte 41.
- Cause: `.pkgdir` is the pre-packaging staging copy. OpenWrt runs `rstrip.sh` on the
  separate `ipkg-x86_64/fakesip` tree before creating the IPK, so the two ELF files are
  not expected to be byte-identical.
- Evidence passed before this point: all package files, integrity, versions,
  architectures, ownership metadata, config mode, source-file identity, both observed
  hosts, logging fallback substring, hardware-address guard, and LuCI content checks.
- Product impact: no defect established.
- Correction: compare the extracted IPK binary with the final `ipkg-x86_64/fakesip`
  packaging tree, then run the remaining extracted-ownership and cleanup assertions.

## F-019: Final IPK Staging Tree Was No Longer Present

- Date observed: 2026-08-24
- Host: Debian jump host
- Scope: identify the correct post-rstrip OpenWrt 22.03 binary
- Diagnostic: `sha256sum` reported that
  `.../fakesip-0.9.1/ipkg-x86_64/fakesip/usr/bin/fakesip` did not exist.
- Command status detail: the compound command ultimately exited zero because a later
  `file` command completed, but the individual `sha256sum` operand failed and is recorded
  here.
- Evidence: the surviving `.pkgdir` binary is reported as unstripped with debug info,
  while the extracted IPK binary has no section header. This confirms why their bytes
  differ.
- Cause: the SDK's transient final package tree is not a durable post-build interface and
  had already been cleaned.
- Product impact: none.
- Correction: compare the helper's copied IPK with the durable SDK `bin/packages`
  artifact, and rely on package extraction plus build logs/content assertions for the
  packaged binary rather than a vanished staging path.

## F-020: Final Router Sample Did Not Print WAN Counters

- Date observed: 2026-08-24
- Device: OpenWrt router, read-only query
- Overall command exit: 0
- Missing output: no lines were printed for `pppoe-wan2`, `pppoe-wancm`, or
  `pppoe-wanct` by the final awk loop.
- Cause: the parser assumed fixed fields after splitting `/proc/net/dev` on both spaces
  and colons; leading whitespace changed the interface-name field position.
- Valid evidence from the same 30-second command: PID 25720 remained stable, queue 513
  packet id advanced from 435337 to 435630, backlog/kernel/user drops stayed zero, RSS
  and VmSize stayed 912/1148 kB, and CPU advanced by one tick.
- Device impact: none; every command was read-only.
- Correction: parse the text after the colon into the documented 16 counters and reread
  the three interface error/drop values.

## Final Resolution Summary

- F-001 was a historical extraction-directory setup error. Corrected verification passed.
- F-002 remains an explicit coverage gap: Debian lacks `iptables` and `ip6tables`. nft
  rollback integration passed; no package was installed solely to close this gap.
- F-003 remains an external tooling gap: no real local Ollama or LM Studio runtime was
  installed or active.
- F-004 remains an external authorization gap: Gemini Code Assist rejected the current
  Workspace request. No model result was used.
- F-005 was corrected with the configured SSH alias/ProxyJump path. Later router reads
  succeeded and remained read-only.
- F-006 and F-007 were atomic patch-context rejections. Smaller exact patches succeeded,
  and the target tests passed.
- F-008 was triaged as known framework, target-shell, intentional splitting, and dynamic
  mock warnings. It established no product defect.
- F-009 was corrected by using the configured `<debian-ssh-alias>` identity. The OpenWrt
  25.12 build completed successfully.
- F-010 through F-012 were artifact-harness assumptions. Correct double-tar IPK parsing,
  stable identifiers, source equality, and the local Node syntax gate replaced them.
- F-013 cleanup completed. Every package-listed misplaced `/root` path is absent. The
  recovery archive SHA-256 is
  `18dbd10bd7770dbf019d57e41834a064bda2f6858a5d229840ac473575e639be`.
- F-014 affected diagnostic labels only and changed no file.
- F-015 was caught in the diff before any build. Final core metadata is x86_64 and final
  LuCI metadata is all in both package formats.
- F-016 failed before SSH execution. The escaped rerun reached Debian.
- F-017 was an anchored-`strings` false negative. The literal exists at binary offset
  46832 inside a compiler-merged line; a substring assertion passed.
- F-018 and F-019 were invalid comparisons against nonfinal or removed SDK staging paths.
  Both copied IPKs are byte-identical to the durable SDK `bin/packages` artifacts, and
  the APK binary is byte-identical to the direct build output.
- F-020 was corrected with colon-delimited `/proc/net/dev` parsing. All three PPP WANs
  reported zero RX/TX errors and drops.

No unrecorded test, command, connection, cleanup, build, or device failure is known at
audit completion. Expected fault-injection diagnostics remain successful negative tests,
not failures.

## F-021: First Install-Test Handoff Patch Had Stale Context

- Date observed: 2026-08-24
- Scope: append the pre-install context and dedicated install-test handoff
- Result: `apply_patch` rejected the patch before changing either file.
- Cause: the patch expected an older final context sentence that had already been
  followed by the source/handoff archive details.
- Impact: none. No repository file changed and no router command or installation ran.
- Correction: anchor the next patch on the current exact final line, then verify both
  the context and install-test handoff before starting the device procedure.

## F-022: Router Backup Script Used an Unavailable stat Binary

- Date observed: 2026-08-24
- Device: OpenWrt 25.12 router
- Scope: pre-install rollback backup
- Exit code: 127
- Diagnostic: `sh: stat: not found`.
- Partial effect: the command created the dated backup directory and copied the six
  FakeSIP/LuCI/UCI files, then stopped before creating the backup archive. FakeSIP was
  not stopped, no package was uploaded, and no package/config/service state changed.
- Cause: this BusyBox image has `ls` and `sha256sum` but no standalone `stat` applet.
- Correction: validate the partial directory, use BusyBox-compatible metadata commands,
  create the tar archive, and hash it before installation. Do not delete the partial
  backup.

## F-023: Router Backup Pull Assumed rsync Existed on OpenWrt

- Date observed: 2026-08-24
- Scope: copy the completed router rollback archive to the Mac
- Result: remote `rsync` was not found and the local rsync transfer exited 127/1.
- Device state: unchanged. The archive remains complete on the router with SHA-256
  `f0987a3c033dddf63fc89da5b6f1b1a1ca1c9dd3647ed68933921f940f491bc0`.
- Cause: this OpenWrt image does not include the rsync package.
- Correction: transfer the exact archive through an SSH base64 stream and verify the
  local SHA against the router value. No router package installation has started.

## F-024: Router Backup Transfer Also Assumed base64 Existed

- Date observed: 2026-08-24
- Scope: transfer the completed router archive and candidate APKs
- Result: OpenWrt reported `ash: base64: not found`; the transfer command exited before
  any candidate upload.
- Device state: unchanged. The complete rollback archive and no candidate package remain
  on the router; FakeSIP was not stopped.
- Local effect: the first pull created only a temporary `.part` output before checksum
  comparison stopped. It is an exact temporary transfer path, not a trusted artifact.
- Correction: use raw SSH stdin/stdout with BusyBox `dd`, then compare SHA-256 on both
  ends and remove/replace only the known temporary `.part` path.

## F-025: macOS base64 Decode Invocation Used the Wrong File-Argument Form

- Date observed: 2026-08-24
- Scope: regenerate and verify the four Base64 handoff copies before installation
- Result: the first verification loop stopped at the first file with
  `base64: invalid argument ...md.b64`; no handoff source file was changed.
- Cause: macOS `base64` requires `-D -i <file>` for file decoding; unlike the assumed
  form, it does not accept the input filename as a positional argument after `-D`.
- Impact: none to source handoffs, router state, package files, or FakeSIP. The loop had
  already regenerated the Base64 output files, but had not yet trusted them as verified.
- Correction: rerun each check with `base64 -D -i <file>.b64 | cmp -s <file> -` and
  record a successful result before the device installation.

## F-026: Queue Query Assumed No Leading Whitespace

- Date observed: 2026-08-24
- Scope: pre-install read-only queue 513 verification
- Result: `grep '^513 '` printed no row even though queue 513 was registered.
- Cause: OpenWrt formats the `/proc/net/netfilter/nfnetlink_queue` row with leading
  spaces. The anchored query was too strict.
- Impact: none to the router or service. A second read-only query using the first field
  (`awk '$1 == 513'`) returned the live row and confirmed PID 31113. No queue 512 data
  was inspected or changed.
- Correction: all future queue checks must select by the parsed first field and preserve
  the raw queue 513 row; never assume the row begins at column zero.

## F-027: Pre-install Handoff PID Became Stale Before Device Mutation

- Date observed: 2026-08-24
- Scope: reconcile the dedicated install-test handoff with the immediate pre-install
  read-only snapshot
- Result: the earlier handoff recorded PID 25720, while the current snapshot showed
  PID 31113. The current service was `running`, and no restart was issued by this turn.
- Cause: not established from the available read-only evidence; the PID changed between
  snapshots, so the earlier value cannot be used as the install baseline.
- Impact: no package or configuration change. Queue 513 was registered to PID 31113,
  with the raw row `513 31113 0 2 65531 0 0 468824 1`; RSS was 916 kB, VmSize 1148 kB,
  one thread, and seven file descriptors.
- Correction: update the install handoff to use PID 31113 and the 2026-08-24T09:05:49Z
  router snapshot; treat the PID change itself as an observed unexplained event, not as
  proof of a restart cause.

## F-028: OpenWrt APK Transaction Rejected the LuCI `arch: all` Package

- Date observed: 2026-08-24
- Device: OpenWrt 25.12.5 x86/64
- Scope: first candidate install attempt after FakeSIP was stopped
- Command: `apk add --allow-untrusted --force-overwrite --force-reinstall` with the
  candidate core and LuCI APK paths
- Result: exit `1`; apk reported `luci-app-fakesip-0.9.1-r19: error: uninstallable`,
  `arch: all`, while resolving `world[luci-app-fakesip...]`.
- Impact: the transaction did not install the candidate packages. FakeSIP remained
  stopped and queue 513 remained absent; no FakeHTTP, queue 512, mwan, or NAT6 state was
  read or changed.
- Cause: not yet established. The candidate LuCI APK metadata uses `arch: all`, while
  this router's apk-tools 3.0.5 rejected it during dependency/world resolution.
- Correction: verify transaction atomicity and inspect the router's installed package
  metadata plus the candidate APK metadata. Do not repeatedly retry the same APK; rebuild
  the LuCI package with the exact architecture convention accepted by this OpenWrt image,
  then rehash and reinstall only after that check.

## F-029: Debian SDK Build Command Was Initially Run in the Mac Shell

- Date observed: 2026-08-24
- Scope: rebuild the corrected OpenWrt 25 APKs
- Result: exit `127`; Mac bash reported `/root/fakesip-audit-20260824/tools/build-openwrt-apk.sh:
  No such file or directory`.
- Cause: the command used the Debian absolute path without wrapping the build command in
  the `<debian-ssh-alias>` SSH invocation.
- Impact: none. No source, SDK, router, package, or service state changed.
- Correction: transfer and hash the builder first, then execute the SDK command explicitly
  through `ssh <debian-ssh-alias>`; do not treat a remote `/root` path as local.

## F-030: First 45-minute Monitor Had a WAN Counter Parser Error

- Date observed: 2026-08-24
- Scope: the first queue513-only 45-minute monitor attempt, invalidated at sample 0
- Result: the monitor correctly read PID `17223`, queue513 PID `17223`, backlog `0`,
  kernel drop `0`, user drop `0`, RSS `904 kB`, VmSize `1148 kB`, one thread, and five
  FDs. Its WAN output falsely placed large byte counters in the TX error/drop columns and
  reported `anomaly=1`.
- Cause: POSIX `ash` parses `$10`, `$11`, and `$12` as `$1` followed by literal digits,
  not as positional parameters 10-12. The parser therefore fabricated values such as
  `33980478831` in the TX error/drop positions instead of reading the actual fields.
  The sample is not a valid network-health result.
- Impact: none to FakeSIP or router configuration. The monitor was interrupted immediately
  with exit `130`; the 45-minute window is void and the local invalid log is retained at
  `fakesip-artifacts/audit-20260824-r19-candidate/monitor/fakesip-r19-45m-20260824.log`.
- Correction: inspect the exact three PPPoE `/proc/net/dev` lines, use named RX fields
  followed by `shift 8` for the TX fields, and run a zero-duration dry check. The dry
  check returned zero RX/TX errors and drops on all three PPPoE interfaces. Restart the
  45-minute window only with this corrected parser; do not count sample 0 or its anomaly.

## F-031: Router Read-only Check Assumed Debian Had a Working SSH Key

- Date observed: 2026-09-02
- Scope: pre-release FakeSIP and queue 513 read-only health check
- Result: the nested SSH command stopped with `Permission denied (publickey,password)`.
- Cause: the command forced batch mode and assumed the Debian jump host already had a
  usable router key. That assumption was false for the current Debian SSH session.
- Impact: none. Authentication failed before any router command ran, so no service,
  queue, configuration, route, or file was read or changed.
- Correction: use the previously authorized password path from the Debian jump host,
  after confirming the password helper is available. Do not retry the same batch-key
  command.

## F-032: Shell Parameter Expansion Collided With the Tool JavaScript Template

- Date observed: 2026-09-02
- Scope: 60-second pre-release queue 513 and WAN counter sampling command
- Result: the orchestration layer rejected the script with a JavaScript syntax error
  before `exec_command` was called.
- Cause: an embedded shell `${...}` parameter expansion was placed inside a JavaScript
  template literal, so the JavaScript parser tried to interpret the shell expression.
- Impact: none. The router, Debian jump host, and local files received no command from
  this failed attempt.
- Correction: construct the command as a plain quoted JavaScript string or avoid shell
  brace parameter expansion in template literals. Verify parsing before starting the
  timed sample.

## F-033: NFQUEUE Copy Range Was Mislabeled as Backlog

- Date observed: 2026-09-02
- Scope: 60-second pre-release queue 513 health sample
- Result: the start sample printed `backlog=65531` even though the raw queue row had a
  zero queue depth.
- Cause: the formatter used field 5, which is NFQUEUE copy range, instead of field 3,
  which is the current queued-packet count in `/proc/net/netfilter/nfnetlink_queue`.
- Impact: no device state changed. The raw fields remained available and show queue
  depth 0, kernel drop 0, and user drop 0; only the generated label was wrong.
- Correction: report field 3 as queue depth, fields 6 and 7 as kernel/user drops, and
  field 8 as packet ID. Preserve raw rows in release evidence so field labels can be
  audited.

## F-034: Untracked Privacy Scan Used grep's `-E` Option With ripgrep

- Date observed: 2026-09-02
- Scope: pre-release privacy scan of untracked handoff and test files
- Result: both ripgrep commands stopped before scanning and reported that the supplied
  value was being parsed as an encoding.
- Cause: `rg` was invoked with grep's `-E` extended-regex option. In ripgrep, `-E`
  selects an encoding and does not enable extended regular expressions.
- Impact: none to repository or device state. Earlier tracked-file scans were completed
  with `git grep`; only this untracked-file pass was invalid.
- Correction: rerun with ripgrep's default regular-expression mode and no `-E`, then
  retain only the corrected results in the privacy decision.

## F-035: LocalAI Review Could Not Start Because Ollama Was Not Listening

- Date observed: 2026-09-02
- Scope: requested LocalAI-assisted pre-release review
- Result: `ai-team status` exited 7; curl could not connect to the configured local
  Ollama endpoint at `127.0.0.1:11434`.
- Cause: the Ollama service was not listening when the status check ran. Deployment files
  were present, but service availability had not been verified in this session.
- Impact: none to FakeSIP, the router, or repository contents. No source was sent to a
  model and the release decision did not use an unavailable model result.
- Correction: inspect and, if needed, restart only the local Ollama LaunchAgent; require
  a successful local status check before requesting the advisory review.

## F-036: Gemini Review Wrapper Was Rejected for Destructive Temp Cleanup Syntax

- Date observed: 2026-09-02
- Scope: privacy-clean public candidate diff review through Gemini CLI
- Result: the local command safety layer rejected the wrapper before process creation
  because its EXIT trap contained `rm -rf`.
- Cause: the temporary-directory cleanup used a recursively destructive command even
  though the directory was expected to remain empty.
- Impact: none. Gemini did not start and no diff or repository data was transmitted.
- Correction: use a newly created empty directory, run Gemini from it, and remove it
  with non-recursive `rmdir` after completion. Do not reuse the rejected wrapper.

## F-037: Gemini Code Assist Authorization Returned 403 Before Review

- Date observed: 2026-09-02
- Scope: requested Gemini pre-release review of the privacy-clean public diff
- Result: Gemini CLI exited 55 during Code Assist onboarding with HTTP 403 and reported
  that the current account did not have a valid product license. It also warned that the
  newly created empty directory was not trusted.
- Cause: the existing OAuth/Workspace authorization is no longer accepted for the
  configured Google Cloud project in this session. The trust warning is separate and
  can be removed with the documented headless trust flag.
- Impact: no model review result exists. Authentication failed before model inference,
  so the release decision must not claim Gemini approval.
- Correction: perform one minimal fallback-model probe with explicit headless trust. If
  it receives the same license denial, stop retrying and rely on executable release
  gates until the user renews Gemini CLI authorization.

## F-038: Staged-tree Privacy grep Hung While Traversing Base64 Files

- Date observed: 2026-09-02
- Scope: final privacy scan of the proposed functional release commit
- Result: `git grep` did not complete within the command window and left its shell and
  grep child running until they were explicitly terminated.
- Cause: the whole staged tree included encoded handoff copies; applying large regular
  expressions through Git's tree reader was an unsuitable scan path for those files.
- Impact: none to staged content or device state. The processes were read-only and were
  terminated after their PIDs and parent relationship were verified.
- Correction: scan decoded Markdown and source files while excluding `*.b64`; validate
  every Base64 copy separately with decode-and-compare. Scan the staged textual diff as
  an additional boundary check.

## F-039: Failure Handoff Base64 Was Stale After the Latest Error Entry

- Date observed: 2026-09-02
- Scope: corrected final privacy and handoff integrity scan
- Result: decode-and-compare reported a mismatch for the failure handoff Base64 copy.
- Cause: F-038 had been appended to the Markdown after the previous Base64 regeneration.
- Impact: none to source or device state. The integrity gate stopped before commit and
  the Markdown remained authoritative.
- Correction: regenerate every existing Markdown/Base64 pair after the final handoff
  edit, decode all pairs, and require byte-for-byte comparison before proceeding.

## F-040: IPK Inspection Assumed an ar Container

- Date observed: 2026-09-02
- Scope: metadata and file-mode inspection of the rebuilt OpenWrt 22.03 IPKs
- Result: Debian `ar` reported `file format not recognized`; the following empty stream
  caused gzip/tar to fail, and the combined inspection command exited nonzero.
- Cause: the inspection command assumed the generated IPKs used an ar container without
  checking their magic bytes or file type first.
- Impact: none to the successfully built IPK files. SHA-256 calculation completed before
  extraction, but control/data inspection remains incomplete until the format is parsed
  correctly.
- Correction: identify each IPK with `file` and leading bytes, then use the matching
  tar/gzip or ar reader. Do not retry `ar` unless the container is confirmed as ar.

## F-041: IPK Control Metadata Leaked the Debian Build Path

- Date observed: 2026-09-02
- Scope: privacy inspection of rebuilt OpenWrt 22.03 release artifacts
- Result: both IPK control records used an absolute Debian path in `Source:` (for
  example a `/root/.../openwrt/fakesip` path).
- Cause: `tools/build-openwrt-ipk.sh` installed each package recipe into the SDK as an
  absolute symlink. OpenWrt followed that path when generating control metadata.
- Impact: release blocker for the two IPKs. Package payloads, versions, ownership, and
  modes were otherwise correct, but these artifacts must not be published.
- Correction: copy package recipe directories into the SDK's standard `package/`
  directory, clean up only those created copies, rebuild both IPKs, and require neutral
  `Source: package/...` metadata with no local absolute path before release.

## F-042: Corrected IPK Build Reused Cached Packages With Old Metadata

- Date observed: 2026-09-02
- Scope: first rebuild after replacing absolute SDK package symlinks with copies
- Result: both IPK SHA-256 values were unchanged and control metadata still contained
  the old absolute `Source:` path; the privacy assertion stopped at the first package.
- Cause: the OpenWrt SDK reused its previously built package artifacts because changing
  only the package injection path did not invalidate all build/package cache stamps.
- Impact: release remains blocked for the IPKs. No invalid artifact was published or
  installed, and the OpenWrt 25 APKs are unaffected.
- Correction: make the helper explicitly clean both local packages after installing the
  copied recipes and before configuration/compile, then rebuild to a new output directory
  and require changed, path-neutral control metadata.

## F-043: Multi-file Cache-clean Patch Had an Invalid Hunk Boundary

- Date observed: 2026-09-02
- Scope: add explicit package clean targets and their smoke assertions
- Result: `apply_patch` rejected the patch during verification and changed no file.
- Cause: the second file marker appeared where the first update hunk still expected a
  context/add/remove line.
- Impact: none. The builder and tests remained at the prior committed state.
- Correction: apply the builder and smoke-test edits as separate, independently verified
  patches, then run syntax and smoke gates before committing.

## F-044: Release Checksum Verification Ran in the Repository Directory

- Date observed: 2026-09-02
- Scope: independent download and checksum verification of the published GitHub release
- Result: `gh release download` placed all assets in a new temporary directory, but the
  following `sha256sum --check SHA256SUMS` and file listing ran in the repository root.
  The checksum command therefore reported that `SHA256SUMS` was missing.
- Cause: the command created and populated `verify_dir` without changing the checksum
  and listing commands to that directory or passing absolute paths to them.
- Impact: none to the published assets, repository, or router. The release download
  completed, but this invocation did not validate the downloaded bytes.
- Correction: run checksum and inventory commands with the temporary directory as their
  working directory, or pass absolute paths. Require all five expected assets and four
  successful checksum lines before declaring remote release verification complete.

## F-045: Base64 Verification Used GNU Syntax and Printed a False Success Line

- Date observed: 2026-09-02
- Scope: regenerate and verify the failure handoff Base64 copy after F-044
- Result: encoding completed, but macOS `base64` rejected the GNU-style
  `--decode FILE` invocation. `cmp` then saw empty input, while a later unconditional
  `printf` still printed a misleading verified message.
- Cause: the command mixed GNU and macOS Base64 syntax and separated verification steps
  with newlines instead of fail-fast `&&` control flow.
- Impact: no source or release artifact was affected. The Base64 file required a new
  verification pass, and the printed success line must not be treated as evidence.
- Correction: use macOS-compatible `base64 -D -i FILE`, connect decode, compare, and
  success output with `&&`, and regenerate the Base64 again after this new failure entry.

## F-046: Release Handoff Patch Assumed the Wrong Paragraph Wrapping

- Date observed: 2026-09-02
- Scope: append remote publication verification to the release artifact handoff
- Result: `apply_patch` rejected the update because its expected context split the final
  paragraph at a different line than the file actually used.
- Cause: the patch was composed from a remembered visual wrap instead of copying the
  exact final lines from the file.
- Impact: none. `apply_patch` changed no file, and the release artifacts and tag were
  untouched.
- Correction: anchor the artifact update to an exact short final sentence copied from
  the file, keep the failure and artifact patches separate, then regenerate and compare
  both Base64 copies.

## F-047: Privacy Pattern Flagged Public Examples and Required RFC1918 Rules

- Date observed: 2026-09-02
- Scope: final tracked-text privacy scan after remote release verification
- Result: the broad `192.168.x.x` expression matched README examples using the standard
  OpenWrt address and source rules that intentionally exclude the full RFC1918 /16.
- Cause: the scan treated every private IPv4 literal as personal data without separating
  public documentation examples and protocol behavior from known lab-specific values.
- Impact: none. The command was read-only and correctly stopped, but its findings were
  false positives rather than privacy leaks.
- Correction: retain broad key, token, credential URL, and personal path checks; scan
  specifically for known lab subnets, hosts, ports, aliases, passwords, and project IDs.
  Review generic private-address matches by context instead of automatically failing.

## F-048: Privacy Scan Conflated PPPoE Device Names With SSH Aliases

- Date observed: 2026-09-02
- Scope: corrected final tracked-text privacy scan
- Result: the scan matched documented `pppoe-*` interface names across historical runtime
  evidence and stopped.
- Cause: the pattern incorrectly treated network device names as equivalent to SSH host
  aliases. The privacy handoff's alias category refers to login/jump-host aliases, while
  PPPoE names are non-authenticating service configuration evidence.
- Impact: none. The command was read-only. No credential or personal identifier was
  exposed by these matches, but the scan required a more precise classification.
- Correction: remove PPPoE device names from the automatic secret gate, continue scanning
  known SSH aliases and lab endpoints, and retain the device names as useful reproducible
  runtime evidence.

## F-049: LuCI Review Used an Obsolete Source Path

- Date observed: 2026-09-05
- Scope: resume the r19 handoff and begin the next LuCI/runtime audit
- Result: `wc` and `sed` failed because the command addressed
  `openwrt/luci-app-fakesip/htdocs/.../fakesip.js`, which does not exist in the current
  package layout.
- Cause: the review reused an older LuCI source-tree path instead of discovering the
  current package files first.
- Impact: none. The commands were read-only; no source, package, or router state changed.
- Correction: locate package files with `rg --files` before reading them. The current
  view is under `openwrt/luci-app-fakesip/root/www/luci-static/resources/view/fakesip/`.

## F-050: Initial Long-run Router Snapshot Used an Exact pgrep Name

- Date observed: 2026-09-05
- Scope: first read-only router snapshot after resuming the r19 long-run audit
- Result: `/etc/init.d/fakesip status` printed `running`, but the following
  `pgrep -x fakesip` returned no PID and made the combined command exit 1.
- Cause: not yet classified at observation time. BusyBox process naming, procd state, and
  the queue 513 owner must be compared before treating the missing exact-name match as a
  service failure.
- Impact: none. The command was read-only and did not restart or modify FakeSIP.
- Correction: query `ubus service list`, the full `ps` command line, queue 513's owner
  PID, and `/proc/PID` directly. Do not use a single exact-name `pgrep` as health proof.
- Resolution: procd, `ps`, queue 513, `/proc/2432/cmdline`, `/proc/2432/comm`, and
  `/proc/2432/status` all identified the same healthy FakeSIP process. On this image,
  `pgrep -x fakesip` still returns 1 while `pgrep -f /usr/bin/fakesip` finds the process;
  exact-name pgrep is therefore excluded from future router health gates.

## F-051: Router Diagnostic Assumed BusyBox Provided od

- Date observed: 2026-09-05
- Scope: inspect the process-name bytes while resolving F-050
- Result: OpenWrt printed `ash: od: not found`. The surrounding command continued and
  `/proc/2432/stat` plus `pgrep -f` output were still collected.
- Cause: the diagnostic assumed the optional `od` utility was installed on the minimal
  router image.
- Impact: none. This was a read-only diagnostic; FakeSIP and queue 513 stayed unchanged.
- Correction: use BusyBox-guaranteed `/proc` text, `cat`, `tr`, `awk`, and procd data for
  router monitoring. Do not depend on optional hex-dump tools.

## F-052: procd Had to SIGKILL a FakeSIP Instance After SIGTERM

- Date observed: 2026-09-05 (event occurred 2026-09-04 20:30:26 GMT)
- Scope: long-run FakeSIP log review before the next release
- Result: procd logged that PID 32057 did not stop on SIGTERM within five seconds and
  sent SIGKILL. PID 2432 then started and currently owns queue 513.
- Cause: under investigation. The signal flag, blocking NFQUEUE receive path, EINTR
  handling, and procd timeout must be reviewed and reproduced on Linux/OpenWrt.
- Impact: high-risk shutdown-path failure. The current replacement instance is healthy,
  but forced termination skips normal cleanup and could leave transient firewall or
  socket state during restart.
- Correction: add a deterministic stop/restart regression that requires normal exit
  before procd's timeout, fix the blocking path if confirmed, and do not publish the next
  release until the router stops without SIGKILL.

## F-053: Shutdown Review Used the Wrong Header Directory

- Date observed: 2026-09-05
- Scope: inspect the signal flag type while investigating F-052
- Result: `sed` reported that `src/globvar.h` did not exist. Other source reads in the
  same command completed, so the combined command output was incomplete for this point.
- Cause: the review assumed headers lived beside C files instead of checking the current
  `include/` layout.
- Impact: none. The read-only command changed no source or router state.
- Correction: locate headers with `rg --files` first. The required file is
  `include/globvar.h`; read it and the NFQUEUE tests before deciding the shutdown fix.

## F-054: Debian Shutdown Reproducer Backgrounded the Build Chain

- Date observed: 2026-09-05
- Scope: isolate F-052 with a no-firewall queue 6513 process on Debian
- Result: the command reported exit 143 and no runtime log. Shell precedence made the
  trailing `&` background the complete `cd && make && fakesip` list, so `$!` identified
  the background shell/list rather than a proven FakeSIP process.
- Cause: build and runtime launch were combined in one asynchronous AND-list.
- Impact: no valid shutdown evidence. The test used unique queue 6513 and `-f`, so it did
  not install firewall rules or affect the router.
- Correction: verify no queue/process remains, finish the build synchronously, launch
  only the FakeSIP executable in the background, confirm `/proc/PID/exe` and queue 6513
  ownership, then time SIGTERM against that confirmed PID.

## F-055: Gemini Review Was Again Rejected Before Inference

- Date observed: 2026-09-05
- Scope: requested strict review of the NFQUEUE shutdown and LuCI patch using Gemini CLI
  0.53.0 with the authorized Google Cloud project environment variable
- Result: Code Assist onboarding returned HTTP 403 `PERMISSION_DENIED` with error 3501,
  stating that the account has no valid product license. The command exited 1.
- Cause: the Workspace/Code Assist entitlement remains unavailable despite the temporary
  project selection; this is the same external authorization class as F-037.
- Impact: no Gemini model inference or review result exists. The source diff was not
  approved by Gemini, and no local or router state changed.
- Correction: do not retry again in this release cycle. Base decisions on executable
  regression tests, sanitizers, compiler analysis, package inspection, and live OpenWrt
  evidence until the user or administrator restores Gemini Code Assist entitlement.

## F-056: No Browser Was Available for the LuCI Visual Baseline

- Date observed: 2026-09-05
- Scope: inspect the live r19 LuCI page through a Debian-backed local HTTP tunnel
- Result: the Browser runtime returned `No browser is available` before opening a tab.
  The SSH tunnel itself started successfully and was then intentionally closed with
  Ctrl-C; its resulting SSH exit 255 is expected termination, not another failure.
- Cause: no in-app or connected supported browser instance was available to the Browser
  runtime in this session.
- Impact: no screenshot baseline can be claimed. No LuCI setting, service, router file,
  or queue was changed.
- Correction: validate the UI through LuCI DOM structure, standard CSS classes, Node
  behavior tests, syntax checks, package inspection, and live HTTP/asset loading. Only
  claim screenshot coverage if a supported browser later becomes available.

## F-057: Init Test Was Invoked Without Its Shell and the Batch Still Exited Zero

- Date observed: 2026-09-05
- Scope: verify the new procd termination timeout and LuCI edits
- Result: direct execution of `tests/test_openwrt_init.sh` returned `Permission denied`
  because the tracked file is not executable. Later independent commands succeeded, so
  the newline-separated batch returned exit 0 despite the missed init behavior test.
- Cause: the command omitted `sh` and did not use fail-fast `&&` control flow.
- Impact: no source or router state changed, but this invocation is not valid complete
  test evidence.
- Correction: invoke the test as `sh tests/test_openwrt_init.sh` and connect every gate
  with `&&`; only the corrected run may be recorded as passing.

## F-058: Test Source Was Copied Into Debian's Product Source Directory

- Date observed: 2026-09-05
- Scope: modified shutdown regression, sanitizer run, and GCC analyzer on Debian
- Result: the debug build failed at link time with duplicate `main`, `fs_nfq_setup`,
  `fs_nfq_cleanup`, and `fs_nfq_loop` definitions.
- Cause: a multi-source `scp` destination was `src/`, so `tests/test_nfqueue.c` was copied
  as `src/test_nfqueue.c`. The Makefile wildcard correctly treated the misplaced file as
  a production source file.
- Impact: no valid result from this batch. The pollution is confined to the disposable
  Debian directory, no process or queue 6513 remains, and the local repository/router are
  unchanged.
- Correction: delete only the exact mistakenly created remote `src/test_nfqueue.c`, copy
  product and test files to their matching directories with separate commands, verify
  the remote file list, then rerun the complete batch fail-fast.
