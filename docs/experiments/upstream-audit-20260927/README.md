# Upstream diagnostic reproductions

These experiments diagnose the unchanged upstream and r22 sources. They are
**not passing acceptance tests for a corrected implementation**: some assertions
intentionally require the bug to reproduce. Do not add them to normal CI without
reversing those expectations after a fix.

Prerequisites: Linux, GCC, ASan/UBSan, libnetfilter_queue development libraries;
for the network probe also root, Python 3, nftables, iproute2 and util-linux.
No external server, router credential or real router is needed.

```sh
# Paths below are placeholders; use separate, disposable build output directories.
make -C /path/to/upstream DEBUG=1 BUILDDIR=/path/to/upstream-build
make -C /path/to/fork DEBUG=1 BUILDDIR=/path/to/fork-build

bash docs/experiments/upstream-audit-20260927/run-comparison.sh \
  /path/to/upstream /path/to/fork /path/to/fork /path/to/results

sudo bash docs/experiments/upstream-audit-20260927/run-ipv6-options.sh \
  /path/to/fork-build/fakesip
```

`run-comparison.sh` reports UDP wire lengths and parser results for both sources,
then runs the existing subprocess regression with an eight-second limit. Expected
on the audited commits: upstream returns 1 at the broken-pipe assertion, fork
returns 0 and also reaches all 16 closed-standard-descriptor/logfile cases.

`packet-contracts.c`'s parser fixtures are structure tests, not checksummed wire
packets. `ipv6-options.py` separately proves reachability with kernel-generated
UDP packets and legal eight-byte, padding-only IPv6 options. Both original and
reply carry the selected options. It probes `-0` and `-1` independently.

The wrapper creates two network namespaces linked by veth and confines firewall
rules and queue 6514 to them. It uses documentation-only addresses and no default
route. It has a 35-second overall limit and cleans up the peer. Six cases take
roughly 13 seconds; inspect its final `REPRODUCED` message and detailed JSON.

Only use the network wrapper for the fork/r22 binary: upstream has an independent
UDP-length defect that breaks the plain-packet control. Its extension-parser bug
is independently reproduced by `packet-contracts.c` and unchanged source lines.

Expected fork results:

| Direction | IPv6 packet | Original | Reply | Decoy | Parser rejections |
| --- | --- | ---: | ---: | ---: | ---: |
| -0 | plain | 1 | 1 | 1 | 0 |
| -0 | Destination Options | 1 | 1 | 0 | 2 |
| -0 | Hop-by-Hop | 1 | 1 | 0 | 2 |
| -1 | plain | 1 | 1 | 1 | 0 |
| -1 | Destination Options | 1 | 1 | 0 | 2 |
| -1 | Hop-by-Hop | 1 | 1 | 0 | 2 |
