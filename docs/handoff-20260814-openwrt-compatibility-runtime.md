# FakeSIP OpenWrt Runtime Handoff

Date: 2026-08-14 (Asia/Taipei)
Repository: /Users/sirtungshenghsiao/Documents/fakesip
Implementation commit: 0a27d0080ffe3794db1030e37bfbfdf120048b15
Planned release tag: v0.9.1-openwrt-r18

## Router installation

Target:

- Host: 192.168.9.1 port 33501
- OpenWrt: 25.12.5 r33051-f5dae5ece4
- Target: x86/64
- Kernel: 6.12.94
- Hostname: cache1
- Package manager: apk

Before installation, the router backup directory was created at:

/root/fakesip-backup-20260814-r18

The same archive was copied through Debian to the local artifact directory:

/Users/sirtungshenghsiao/Documents/fakesip-artifacts/openwrt-0.9.1-r18-20260814/router/fakesip-backup-20260814-r18.tgz

The backup archive SHA-256 is
46cc694c5d2bab78bab3db68c2d006b681c9c68b85c8f383cfa6494935537ff4.

## Install result

The two APK files were transferred through Debian and installed with:

```sh
apk add --allow-untrusted /tmp/fakesip-0.9.1-r18.apk /tmp/luci-app-fakesip-0.9.1-r18.apk
```

Installed package output:

- fakesip-0.9.1-r18
- luci-app-fakesip-0.9.1-r18

The old user configuration remained unchanged:

```text
7b82ffa482c8da5fd78f9e874a4efe01da951fb5f809b57320ab471f810a8739  /etc/config/fakesip
```

The package manager left `/etc/config/fakesip.apk-new` because the existing
configuration was preserved. Do not replace the active configuration without
reviewing that file and merging settings deliberately.

## FakeSIP health check

After `/etc/init.d/fakesip restart`:

- service status: running
- PID: 13251
- command includes `-1 -4 -6 -s`, three IMS URIs, `-n 513`, `-r 1`, `-t 3`,
  and interfaces pppoe-wan2, pppoe-wancm, pppoe-wanct
- RSS: 836 kB
- VmSize: 1148 kB
- RssAnon: 96 kB
- threads: 1
- file descriptors: 7
- queue 513 backlog and observed kernel/user drop counters: 0
- queue packet sequence advanced during four samples over 30 seconds
- no FakeSIP error, warning, fail, OOM, or segfault lines appeared after the
  restart

The queue 513 rules remained installed and the service was not changed after
the observation window. FakeHTTP and queue 512 were not operated by this
installation test.

## Next actions

1. Create the final tag v0.9.1-openwrt-r18 on the commit that includes these
   six handoff files.
2. Push the branch and tag to the fork remote.
3. For an older OpenWrt release, build from its exact SDK and install the
   matching IPK after confirming the firewall backend and kernel modules.
4. Keep the router backup and the local artifact directory until the new
   release has been observed in normal operation.
