# FakeSIP Handoff: Runtime Evidence

Status: evidence record, not a claim of uninterrupted uptime.
Observation date: 2026-08-13 Asia/Taipei. Router timestamps below are GMT.

## Scope

- Repository: `<local-fakesip-worktree>`
- Branch: `codex/fakesip-bug-findings`
- Repository HEAD before this audit: `0856ee0`
- Device scope: FakeSIP and queue 513 only.
- Router access path: Mac -> Debian `<debian-jump-host>` -> OpenWrt
  `<openwrt-router>:<router-ssh-port>`.

## Observed Router State

- OpenWrt `25.12.5`; kernel `6.12.94`.
- Router uptime at `2026-08-13 05:15:36 GMT`: `8 days, 9:33`.
- Installed package: `fakesip-0.9.1-r17`.
- UCI: enabled, silent `1`, queue `513`, repeat `1`, TTL `3`, IPv4 and IPv6,
  outbound, profile `china_all`.
- Selected logical networks: `wan2`, `wancm`, `wanct`.
- Running devices: `pppoe-wan2`, `pppoe-wancm`, `pppoe-wanct`.
- Running command PID: `11884`.
- Process state: sleeping; VmSize `1148 kB`; VmRSS `884 kB`; threads `1`; FDs
  `7`.

## Process Age Derivation

This is derived evidence, not a direct service log claim:

- `/proc/11884/stat` start ticks: `69413485`.
- `/proc/stat` boot epoch: `1785872517`.
- Linux clock ticks: `100` per second.
- Derived process start epoch: `1786566651.85` seconds since Unix epoch.
- At the observation time, derived process age was approximately `31807` seconds
  (about 8 hours 50 minutes), not two days.

Therefore router uptime must not be reported as FakeSIP uptime.

## Queue 513 Raw Evidence

Raw `/proc/net/netfilter/nfnetlink_queue` row before a 60-second wait:

```text
  513  11884     0 2 65531     0     0   408430  1
```

Raw row after the wait:

```text
  513  11884     0 2 65531     0     0   409269  1
```

The PID stayed constant and the two drop fields stayed `0`. The sequence-like
counter advanced by `839`; no semantic interpretation beyond the raw evidence
is asserted here.

## Interface Counters

At the snapshot, `pppoe-wan2`, `pppoe-wancm`, and `pppoe-wanct` each reported
zero RX errors, zero RX drops, zero TX errors, and zero TX drops.

## Logs And Limits

- `logread -e fakesip` returned no retained lines at the later observation.
- `dmesg` matched only unrelated firmware/BIOS text for the search terms used;
  no FakeSIP, NFQUEUE, OOM, segfault, or kernel BUG evidence was found.
- Empty retained logs do not prove that no older restart occurred; OpenWrt
  syslog is a bounded ring buffer.
- No router configuration or binary was changed during this audit.
