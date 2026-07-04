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

## Downgraded Or Unconfirmed Findings

### IPv6 nft `icmp type time-exceeded`

File: `src/ipv6nft.c`

This originally looked suspicious because ICMPv6 is normally written with
`icmpv6`. However, Debian 13's `nft -c` accepted the current rule, and
`fakesip -a -6` started and cleaned up successfully. Treat this as a
compatibility/style concern rather than a confirmed bug.

### Duplicate nft Ruleset Apply

File: `src/ipv6nft.c`

`fs_nft6_setup()` calls `fs_execute_command(nft_cmd, 0, nft_conf_buff)` twice.
On Debian 13 this did not break startup, but the second call is redundant and
its result is ignored.

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
- nft IPv6 syntax checks
- iptables-restore syntax checks when available
