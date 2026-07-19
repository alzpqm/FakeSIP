# FakeSIP Bug Findings

This note records the bugs found during Codex review and Debian smoke testing.
It is intentionally kept in the repository so the context is not lost between
assistant sessions.

## Test Environment

- Repository under review: `MikeWang000000/FakeSIP`
- Debian test host: Debian GNU/Linux 13 (trixie), Linux 6.12, x86_64
- Toolchain: GCC 14.2, GNU Make 4.4, nftables 1.1.3
- Build result: `make DEBUG=1` succeeds with installed
  `libnetfilter-queue-dev`, `libnfnetlink-dev`, and `libmnl-dev`.
- Runtime smoke: `build/fakesip -f -a -6` and `build/fakesip -a -6`
  both start and exit cleanly when interrupted by `timeout`.
- OpenWrt runtime host: OpenWrt 25.12.5, Linux 6.12.94, hostname `cache1`.
- OpenWrt SDK: OpenWrt 25.12.5 x86/64 SDK, GCC 14.3.0, musl.

## Current Branch Fix Status

This branch now contains code fixes for:

- IPv4 and IPv6 generated UDP length fields
- outbound original-packet duplication
- IPv6 iptables fallback using IPv4 tooling
- source-info cache population and circular lookup order
- missing unknown-ethertype format argument
- OpenWrt SDK Makefile issues around `build/` creation and empty `STRIP`
- redundant IPv6 nft ruleset application
- defensive cleanup and argument guards in payload/process setup paths

Validation performed through 2026-07-05 Asia/Taipei:

- Debian `make DEBUG=1` succeeded with GCC 14.2.
- Debian `make DEBUG=1 CFLAGS="-fanalyzer"` succeeded with no remaining
  analyzer warnings after the defensive guard fixes.
- Runtime smoke tests for `build/fakesip -f -a -4` and `build/fakesip -a -6`
  started cleanly and exited normally when interrupted by `timeout`.
- A Debian network-namespace regression using a public-test subnet delivered
  exactly one fake SIP payload and exactly one original UDP payload:
  `ORIG_COUNT=1 FAKE_COUNT=1`.
- OpenWrt SDK x86_64/musl package compile succeeded, producing
  `fakesip-0.9.1.1-r1.apk` and a `0.9.1-codex` test binary.
- The OpenWrt test binary was copied to `/tmp/fakesip-codex`, run temporarily,
  and the original router service was restored afterward.

## Confirmed Bugs

### IPv4 UDP Length Is Too Short

File: `src/ipv4pkt.c`

`fs_pkt4_make()` sets:

```c
udph->len = htons(udp_payload_size);
```

The UDP length field must include the UDP header. It should be:

```c
udph->len = htons(sizeof(*udph) + udp_payload_size);
```

Impact: generated IPv4 fake UDP packets are malformed and may be dropped by the
receiver before the SIP payload can be inspected.

### IPv6 UDP Length Is Too Short And Not Network-Ordered

File: `src/ipv6pkt.c`

`fs_pkt6_make()` sets:

```c
udph->len = udp_payload_size;
```

This has two problems:

- it excludes the UDP header length
- it is not converted with `htons()`

Impact: generated IPv6 fake UDP packets are malformed and may be dropped.

### Outbound Original UDP Packets Are Duplicated

File: `src/rawsend.c`

In the `PACKET_OUTGOING` branch, FakeSIP manually forwards the original packet:

```c
nbytes = sendto_snat(sll, daddr, pkt_data, pkt_len);
```

Then it returns `NF_ACCEPT`, so the queued kernel packet is accepted too. A
Debian network namespace test confirmed this behavior:

- baseline without FakeSIP: receiver got one `ORIGINAL` datagram
- with FakeSIP enabled: receiver got two identical `ORIGINAL` datagrams

Impact: outbound traffic is duplicated. A likely fix is to avoid manually
sending the original packet, or return `NF_DROP` after manual forwarding. The
right choice depends on why SNAT/raw forwarding is needed there.

### IPv6 iptables Fallback Uses IPv4 iptables/ICMP Matchers

File: `src/ipv6ipt.c`

The IPv6 iptables setup contains:

```c
{"iptables", "-w", "-t", "mangle", "-A", "FAKESIP_S", "-p", "icmp",
 "--icmp-type", "11", "-j", "DROP", NULL},
```

This is in the IPv6 setup path, so it should use IPv6 tooling/matchers, such as
`ip6tables` and an ICMPv6 time-exceeded matcher.

Impact: the iptables fallback path can fail or apply the wrong rule family when
IPv6 support is requested.

### Source-Info Cache Is Not Populated

Files: `src/srcinfo.c`, `src/rawsend.c`

`fs_srcinfo_get()` is used in the outbound path, but no call to
`fs_srcinfo_put()` was found in the codebase.

Impact: the TTL/MAC cache appears unused, so outbound hop estimation and
link-layer address recovery do not work as intended.

### Source-Info Ring Lookup Underflows

File: `src/srcinfo.c`

`fs_srcinfo_get()` indexes the circular buffer with:

```c
info = &srci[(srci_end - i - 1) % CAPACITY];
```

Because `srci_end` and `i` are unsigned, this underflows when `srci_end == 0`.
The modulo still yields an index, but not the intended newest-to-oldest order.

Impact: cache lookups can inspect entries in the wrong order, especially after
wraparound.

### Missing Format Argument

File: `src/rawsend.c`

The unknown ethertype log message contains `%04x` but does not pass
`ethertype`.

Impact: undefined behavior if the unknown-ethertype branch is reached.

### Makefile Link Target Does Not Require Build Directory

File: `Makefile`

The link target wrote `build/fakesip` without an order-only dependency on
`build/`. OpenWrt SDK parallel/package builds can clean and recreate the build
tree before invoking the sub-make, so the final link can fail if the target
directory is not guaranteed to exist.

Impact: OpenWrt SDK builds can fail at final link time with
`build/fakesip: No such file or directory`.

### Empty STRIP Executes The Target Binary

File: `Makefile`

When OpenWrt SDK invoked the sub-build with `STRIP=""`, the recipe line:

```make
$(STRIP) $@
```

expanded to just:

```sh
build/fakesip
```

That tries to execute the newly cross-compiled musl binary on the build host.

Impact: cross-builds can fail after a successful link. The observed failure was
`build/fakesip: No such file or directory`, caused by Debian attempting to run
an OpenWrt/musl executable.

## OpenWrt Runtime Findings

### Multi-Instance OpenWrt Setup Starves Later Queues

The OpenWrt service was running three FakeSIP instances:

```sh
/usr/bin/fakesip -i pppoe-wan2  -1 -4 -n 513 -w /tmp/fakesip-wan2.log
/usr/bin/fakesip -i pppoe-wancm -1 -4 -n 514 -w /tmp/fakesip-wancm.log
/usr/bin/fakesip -i pppoe-wanct -1 -4 -n 515 -w /tmp/fakesip-wanct.log
```

All instances install rules into the same `table ip fakesip` and the same
`fs_rules` chain. In the observed ruleset, all WAN interface jumps eventually
hit one shared chain like this:

```nft
meta mark & 0x00010000 == 0x00010000 return
meta l4proto udp ct packets 1-5 queue flags bypass to 513
meta mark & 0x00010000 == 0x00010000 return
meta l4proto udp ct packets 1-5 queue flags bypass to 515
meta mark & 0x00010000 == 0x00010000 return
meta l4proto udp ct packets 1-5 queue flags bypass to 514
```

The first matching queue rule consumes the packet, so the later queue rules are
effectively unreachable for matching UDP traffic. This matches the logs: the
first queue's log kept growing while the other logs were stale or much less
active.

Operational impact: starting one FakeSIP process per WAN with different queue
numbers does not isolate traffic by interface. A safer deployment shape is one
process with all WAN interfaces on one queue, or a code change that creates
per-instance/per-interface chains instead of sharing a single `fs_rules` chain.

The OpenWrt r11 package prevents this invalid shape by exposing and starting
only the `main` UCI section. Multi-WAN deployments add all interface names to
that single process and queue.

### `-1` Explains The `UDP(~)` Skip Lines

The OpenWrt service starts each instance with `-1`, which sets
`g_ctx.outbound = 1` but leaves `g_ctx.inbound = 0`. In `src/rawsend.c`, the
`PACKET_OUTGOING` path does this:

```c
if (!g_ctx.inbound) {
    E_INFO("%s:%u <===UDP(~)=== %s:%u", ...);
    return NF_ACCEPT;
}
```

Therefore the repeated `UDP(~)` log lines are expected for packets that enter
that branch while the instance is running with only `-1`.

### OpenWrt Single-Instance Test

On 2026-07-04, a temporary OpenWrt test was run by stopping the service,
starting one FakeSIP process for all three WAN interfaces, sending a few UDP
probes with `socat`, collecting logs, and restoring the original service.

Temporary command:

```sh
/usr/bin/fakesip -i pppoe-wan2 -i pppoe-wancm -i pppoe-wanct \
  -4 -n 513 -w /tmp/fakesip-single-test2.log
```

The temporary nft ruleset had one queue rule only:

```nft
meta mark & 0x00010000 == 0x00010000 return
meta l4proto udp ct packets 1-5 queue flags bypass to 513
```

Observed result:

```text
FAKE count: 8
UDP skip count: 0
LOCAL skip count: 0
```

A prior natural-traffic run with the same single-instance shape produced:

```text
FAKE count: 109
UDP skip count: 0
LOCAL skip count: 0
```

The original three-instance service was restored after the test.

Important caveat: this operational workaround makes FakeSIP reach the fake-send
branches, but it does not fix the source-level UDP length bugs documented
above. Those malformed generated packets can still prevent effective
camouflage until the packet builders are fixed.

Suggested OpenWrt service shape for further testing:

```sh
procd_set_param command "$PROG" \
  -i pppoe-wan2 -i pppoe-wancm -i pppoe-wanct \
  -4 -n 513 -w /tmp/fakesip-allwan.log
```

This suggestion was tested temporarily only; it was not left installed on the
router.

### OpenWrt Fixed-Binary Test

After applying the source fixes in this branch, an OpenWrt x86_64/musl binary
was built with the OpenWrt 25.12.5 SDK and copied to the router as:

```sh
/tmp/fakesip-codex
```

The binary identified itself as:

```text
FakeSIP version 0.9.1-codex
```

It was run temporarily with:

```sh
/tmp/fakesip-codex -i pppoe-wan2 -i pppoe-wancm -i pppoe-wanct \
  -1 -4 -n 513 -r 1 -w /tmp/fakesip-codex-test.log
```

DNS queries were sent from the router to `8.8.8.8`, `1.1.1.1`, `223.5.5.5`,
and `119.29.29.29`; all `nslookup example.com <server>` commands returned
successfully.

Observed log counts:

```text
FAKE_COUNT=35
UDP_SKIP_COUNT=32
LOCAL_SKIP_COUNT=0
```

Example fixed-binary log lines:

```text
119.29.29.29:53 ===UDP===> 10.47.15.242:43510
119.29.29.29:53 <===FAKE(*)=== 10.47.15.242:43510
```

The `UDP(~)` lines are still expected for packets that enter the skipped
direction while running with `-1`; the important result is that the fixed binary
entered the fake-send path and produced `FAKE(*)` records during real OpenWrt
traffic. The original three-process service was restored after the test.

### OpenWrt Active Deployment

On 2026-07-05 Asia/Taipei, the fixed binary was deployed on the OpenWrt router
for active use.

Router-side backup:

```text
/root/fakesip-backup-20260704-212905
/root/fakesip-backup-20260704-212905.tgz
```

Mac-side backup:

```text
/Users/sirtungshenghsiao/Documents/fakesip-backups/fakesip-backup-20260704-212905.tgz
```

Backup tarball SHA-256:

```text
6631bb42efb0b9db3eca83d2eaff2f0abc330a0493d02d94232489793353ad2f
```

Installed binary:

```text
/usr/bin/fakesip
sha256: 296139f463e668d016208eb551a23138c8e30d926b7bed017903a90d241ea8b1
```

The active init script now starts one process for all three WAN interfaces:

```sh
/usr/bin/fakesip -i pppoe-wan2 -i pppoe-wancm -i pppoe-wanct \
  -1 -4 -n 513 -w /tmp/fakesip-allwan.log
```

The active nft ruleset was verified to contain a single queue rule:

```nft
meta l4proto udp ct packets 1-5 queue flags bypass to 513
```

Post-deployment verification:

```text
NSLOOKUP_8.8.8.8_RC=0
NSLOOKUP_1.1.1.1_RC=0
NSLOOKUP_223.5.5.5_RC=0
NSLOOKUP_119.29.29.29_RC=0
FAKE_COUNT=44
UDP_SKIP_COUNT=89
LOCAL_SKIP_COUNT=0
```

Rollback command on the router:

```sh
/root/fakesip-backup-20260704-212905/rollback.sh
```

### OpenWrt UDP/443 Bypass Test And Global Mode Revert

After active deployment, web images were reported to load slowly. The router log
showed FakeSIP was processing UDP/443 traffic:

```text
UDP443_LINES=2191
```

Recent samples included `FAKE(*)` records for remote port `443`, which is
consistent with HTTP/3/QUIC being queued and spoofed. That can delay image and
media loads while browsers or CDNs retransmit or fall back to TCP.

A temporary live nft bypass was tested by inserting UDP/443 returns before the
queue rule:

```nft
udp dport 443 return
udp sport 443 return
meta mark & 0x00010000 == 0x00010000 return
meta l4proto udp ct packets 1-5 queue flags bypass to 513
```

Post-change 30-second sample:

```text
SAMPLE_LINES=56552..56731
NEW_443_LINES=0
NEW_443_FAKE_LINES=0
NEW_FAKE_LINES=78
```

This confirmed the cause, but the bypass was removed afterward because the
deployment goal is global UDP camouflage. The current active router ruleset has
no UDP/443 exception and keeps only the queue rule:

```nft
meta mark & 0x00010000 == 0x00010000 return
meta l4proto udp ct packets 1-5 queue flags bypass to 513
```

The active init script was also reverted to the no-bypass single-process
configuration.

Mac-side backup from the temporary bypass test:

```text
/Users/sirtungshenghsiao/Documents/fakesip-backups/fakesip-backup-20260704-212905-quic-bypass.tgz
sha256: bc12170388d6cb9b5fb0d394c58580a7e0f82ebd900b39d56d3679b123d8a987
```

Mac-side backup after reverting to global no-bypass mode:

```text
/Users/sirtungshenghsiao/Documents/fakesip-backups/fakesip-backup-20260704-212905-global-no-bypass.tgz
sha256: d707d7d985dfce263262c70a7ca761a6c9cad0febb1fccee4402fc4b3755d331
```

### Interface-Scoped ICMP Drops Still Break MTR

The interface-scoping fix prevented unrelated interfaces from being affected,
but each selected WAN still dropped every ICMP/ICMPv6 time-exceeded reply. On
2026-07-18, `mtr` to mainland China targets showed every intermediate IPv4 and
IPv6 hop as `???`, while the corresponding nft drop counters increased.

The fix tags forged IPv4 packets with IP ID `0x4653` and forged IPv6 packets
with flow word `0x60046553`. nftables now inspects the packet quoted inside the
ICMP error and drops only matching FakeSIP replies. Normal MTR replies pass. The
iptables fallback no longer installs a broad time-exceeded drop rule. This fix
is packaged in OpenWrt r12.

### Long-Running Process Robustness

A follow-up audit found several defensive and recovery gaps:

- `th_payload_get()` dereferenced its output pointers and the current payload
  node without validation.
- signal handlers wrote an ordinary `int` instead of a volatile
  `sig_atomic_t` flag.
- numeric options and `/proc` PID names were accepted without checking
  `strtoull()` overflow or trailing characters.
- the source-info ring relied on implicit initialization markers instead of an
  explicit valid-entry count and argument/index guards.
- recoverable NFQUEUE receive errors counted toward process termination.
- command pipe write, close, and interrupted `waitpid()` failures could be
  hidden by a successful child exit.

The fixes add explicit API failures, strict parsing, bounded cache accounting,
capped NFQUEUE backoff, pipe error propagation, and early SIGPIPE handling. The
same change also accepts an exact 1200-byte custom payload, avoids direct
`realloc()` assignment, and replaces the payload random-number multiplication
with width-aware composition. These fixes are packaged in OpenWrt r13.

Run the focused regression tests with:

```sh
make DEBUG=1
./tools/core-regression-test.sh
```

## Downgraded Or Unconfirmed Findings

### IPv6 nft `icmp type time-exceeded`

File: `src/ipv6nft.c`

This originally looked suspicious because ICMPv6 is normally written with
`icmpv6`. However, Debian 13's `nft -c` accepted the current rule, and
`fakesip -a -6` started and cleaned up successfully. Treat this as a
compatibility/style concern rather than a confirmed bug.

## Reproduction Notes

Run the smoke test on a Debian host with root privileges:

```sh
sudo bash tools/debian-smoke-test.sh
cat /tmp/fakesip-smoke/smoke.log
```

The script performs:

- host/toolchain capture
- debug build
- static probes for the confirmed source-level issues
- nft tagged ICMP/ICMPv6 syntax checks
