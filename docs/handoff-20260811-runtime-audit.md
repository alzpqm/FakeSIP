# FakeSIP Handoff: 2026-08-11 Runtime Audit

This file is the source of truth for the next context after compaction. Do not
infer facts that are not listed as observed evidence.

## Scope

- Repository: `/Users/sirtungshenghsiao/Documents/fakesip`
- Branch: `codex/fakesip-bug-findings`
- HEAD at audit start: `0c1717419fb85c356ed6877df047083026798267`
- Remote: `fork` (`https://github.com/alzpqm/FakeSIP.git`)
- Device scope: FakeSIP and queue 513 only. Do not read or modify FakeHTTP or
  queue 512 unless the user explicitly changes the boundary.
- Router access: Debian jump host `192.168.9.190`, then OpenWrt
  `192.168.9.1:33501`.

## Evidence Rules

- Separate observed output from hypotheses.
- The router's `uptime` is not FakeSIP uptime.
- `logread` is a bounded ring buffer; absence of old entries cannot prove that
  no old restart occurred.
- Do not report a bug as fixed without a reproducer or a test that fails before
  the change and passes after it.
- Back up UCI, the init script, binary, package metadata, and relevant nft state
  before changing the router.

## Local State

- The worktree was clean at audit start.
- Latest pushed changes are the payload rotation fix (`ebe90f7`) and the
  OpenWrt source pin/package release update (`0c17174`).
- Installed OpenWrt core package is `fakesip-0.9.1-r17`.
- Local deployment and runtime backups:
  - `/Users/sirtungshenghsiao/Documents/fakesip-backups/fakesip-r17-20260809-0040/`
  - `/Users/sirtungshenghsiao/Documents/fakesip-backups/fakesip-30m-nonsilent-backup-20260809-065231/`

## Router Snapshot

Observed on 2026-08-11; router timestamps are GMT.

- OpenWrt: `25.12.5`, kernel `6.12.94`
- Router uptime: `6 days, 12:29` at `08:11:16` GMT
- UCI: enabled, `silent=1`, queue `513`, repeat `1`, TTL `3`, IPv4 and IPv6,
  outbound mode, profile `china_all`
- Logical networks: `wan2`, `wancm`, `wanct`
- Running command resolved to `pppoe-wan2`, `pppoe-wancm`, `pppoe-wanct`
- Current PID: `24699`
- RSS: `908 KB`; VM size: `1148 KB`; threads: `1`; file descriptors: `7`
- `/proc/net/netfilter/nfnetlink_queue` queue 513 row showed PID `24699`,
  backlog `0`, kernel drop `0`, and userspace drop `0`
- Current dmesg search found no FakeSIP, NFQUEUE, OOM, segfault, or BUG entry.
  The only matched BUG text was unrelated firmware/BIOS wording.
- The final known PPPoE interface checks from the 30-minute test showed zero
  RX/TX errors and zero drops on `pppoe-wan2`, `pppoe-wancm`, and
  `pppoe-wanct`.

## Confirmed Runtime Event

The retained `logread` window contains one synchronized WAN reconnect on
2026-08-10:

1. `pppoe-wan2`, `pppoe-wancm`, and `pppoe-wanct` went down around 20:30:00.
2. The interfaces came back up and firewall reloads were logged.
3. FakeSIP PID `16816` exited normally at 20:30:22 and PID `19864` started.
4. PID `19864` exited normally at 20:30:59 and PID `24699` started at 20:31:00.

There was no crash, segfault, OOM, or queue drop in the retained evidence.
This is consistent with the current init design registering logical-network
reconnect triggers, but repeated reloads during one multi-WAN reconnect are a
candidate for improvement, not yet a confirmed defect.

## 30-Minute Non-Silent Test

The previous test completed on 2026-08-09. `silent=0` was applied, then 31
samples covered 30 minutes. PID `26938` remained constant; RSS stayed around
`900-912 KB`, VM size `1148 KB`, FD `7`, thread `1`; queue 513 backlog/kernel
drop/userspace drop stayed at zero; the tested error-keyword count stayed zero.
After the final sample, `silent=1` was restored and the service was restarted
to PID `16510`. The final state was running with `-s` and queue 513.

## Current Decision

- No new core memory-safety or NFQUEUE runtime bug is proven by the current
  evidence.
- Do not claim two days of uninterrupted FakeSIP uptime.
- Investigate multi-WAN reconnect reload coalescing locally before changing the
  router. Any change needs a shell/init regression test and a controlled
  router backup.

## Follow-up Snapshot

The later read-only check on 2026-08-11 showed:

- Router uptime: `6 days, 12:29` at `08:11:16` GMT.
- FakeSIP package: `0.9.1-r17`; current PID `24699`; `silent=1`.
- RSS `908 KB`, VM size `1148 KB`, one thread, seven file descriptors.
- Queue 513 row: PID `24699`, backlog `0`, kernel drop `0`, userspace drop `0`.
- Retained FakeSIP log window: 18 lines, from `2026-08-10 20:30:22` through
  `20:31:00` GMT; two normal exits, zero matched error keywords.
- The surrounding netifd/mwan3/firewall records show all three selected PPPoE
  devices going down and up, followed by firewall reloads. This supports the
  reconnect explanation for the two restarts.
- No router change was made during this audit.
