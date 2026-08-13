# FakeSIP Handoff: Claims And Next Actions

This file separates confirmed facts from hypotheses for the next context.

## Confirmed

- The live router is using FakeSIP `0.9.1-r17`.
- The live process is bound to queue `513` and the configured three PPPoE
  devices.
- The 60-second observation kept the PID constant and queue 513 drop fields at
  zero.
- No new reproducible core crash, memory leak, OOM, segfault, or NFQUEUE drop
  issue was found.

## Not Confirmed

- Two days of uninterrupted FakeSIP runtime is not confirmed; the current PID
  age is only about 8 hours 50 minutes.
- An empty retained `logread` result is not proof of a clean historical window.
- The cause of any download-speed change is not established by this audit.

## Improvement Candidate, Not A Fix

Earlier retained evidence showed multiple PPPoE interfaces reconnecting close
to one another and FakeSIP being reloaded more than once. The current init
script intentionally registers one logical-network trigger per selected
network. This may be an opportunity to coalesce reloads, but no debounce design
has been proven safe and no change should be deployed yet.

## Required Before Any Runtime Change

1. Reproduce the multi-WAN reconnect with a local procd/init test.
2. Define the expected number of service restarts for one grouped reconnect.
3. Add a regression test that fails before the change and passes after it.
4. Back up UCI, init script, binary, package metadata, and relevant firewall
   state.
5. Deploy only after a controlled router test and a rollback check.

## Handoff Rule

At every context compaction and at research completion, update all six files in
this handoff set. Keep the three `.md` files readable and regenerate the three
`.b64` files from their exact contents. Never promote a hypothesis to a bug
without evidence.
