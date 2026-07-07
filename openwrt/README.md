# FakeSIP OpenWrt Package

This directory contains an OpenWrt package recipe, a UCI config, and a procd
service script for FakeSIP.

## Build With The OpenWrt SDK

For OpenWrt 25 APK packages, the most direct path is:

```sh
./tools/build-openwrt-apk.sh /path/to/openwrt-sdk
```

The script builds from the current working tree, creates both `fakesip` and
`luci-app-fakesip`, and writes APKs under
`/path/to/openwrt-sdk/bin/packages/x86_64/base/` by default.

Copy the package recipes into an OpenWrt SDK or buildroot:

```sh
cp -r /path/to/FakeSIP/openwrt/fakesip /path/to/openwrt-sdk/package/fakesip
cp -r /path/to/FakeSIP/openwrt/luci-app-fakesip /path/to/openwrt-sdk/package/luci-app-fakesip
cd /path/to/openwrt-sdk
make defconfig
make package/fakesip/compile V=s FAKESIP_SRC_DIR=/path/to/FakeSIP
make package/luci-app-fakesip/compile V=s
```

`FAKESIP_SRC_DIR` builds the package from your local working tree. Without it,
the recipe fetches the pinned fork commit in `openwrt/fakesip/Makefile`.

The package artifact is written under `bin/packages/`.

Runtime prerequisites on the router:

- `nft` command from `nftables-json` or `nftables-nojson`
- NFQUEUE kernel support, usually `kmod-nft-queue`
- LuCI installed before installing `luci-app-fakesip`

## Install On OpenWrt

OpenWrt 25.12 and newer use `apk`:

```sh
scp bin/packages/*/*/fakesip-*.apk root@192.168.1.1:/tmp/
scp bin/packages/*/*/luci-app-fakesip-*.apk root@192.168.1.1:/tmp/
ssh root@192.168.1.1
apk add --allow-untrusted /tmp/fakesip-*.apk
apk add --allow-untrusted /tmp/luci-app-fakesip-*.apk
```

If `/etc/init.d/fakesip` was edited before installing the package, `apk` may
preserve the existing file and write the packaged service as
`/etc/init.d/fakesip.apk-new`. Review and merge it before expecting LuCI/UCI
changes to control the running service.

OpenWrt 24.10 and older use `opkg`:

```sh
scp bin/packages/*/*/fakesip_*.ipk root@192.168.1.1:/tmp/
scp bin/packages/*/*/luci-app-fakesip_*.ipk root@192.168.1.1:/tmp/
ssh root@192.168.1.1
opkg install /tmp/fakesip_*.ipk
opkg install /tmp/luci-app-fakesip_*.ipk
```

## Configure And Run

The default config is disabled so installation never changes traffic by
surprise. Enable it and point it at your WAN network:

In LuCI, open **Services > FakeSIP**, enable the `main` instance, set the WAN
network or Linux interface, save/apply, then use the Start or Restart button.

The same setup from SSH is:

```sh
uci set fakesip.main.enabled='1'
uci -q delete fakesip.main.network
uci add_list fakesip.main.network='wan'
uci set fakesip.main.ipv4='1'
uci set fakesip.main.ipv6='1'
uci set fakesip.main.outbound='1'
uci set fakesip.main.inbound='0'
uci set fakesip.main.silent='1'
uci -q delete fakesip.main.log_file
uci commit fakesip

/etc/init.d/fakesip enable
/etc/init.d/fakesip start
```

For multi-WAN, add each logical network to the same instance. Running one
FakeSIP process per WAN with separate queue numbers can make later queues
unreachable because all instances share the same nft table and chain names.

```sh
uci add_list fakesip.main.network='wan2'
uci add_list fakesip.main.network='wan3'
uci commit fakesip
/etc/init.d/fakesip restart
```

If you already know the Linux device names, use `interface` instead:

```sh
uci -q delete fakesip.main.network
uci add_list fakesip.main.interface='pppoe-wan'
uci commit fakesip
/etc/init.d/fakesip restart
```

If both `network` and `interface` are present, the init script resolves and
deduplicates them before starting FakeSIP. Values in `network` may be logical
OpenWrt network names such as `wan`; Linux devices such as `pppoe-wan` are also
accepted for robustness, but keeping device names under `interface` is clearer.

## Check It

```sh
/etc/init.d/fakesip status
logread -e fakesip
tail -f /tmp/fakesip.log
nft list table ip fakesip
```

The service should have one queue rule for the configured instance, usually
queue `513`.

The package enables silent mode by default for long-running routers. Set
`fakesip.main.log_file` only while debugging; high-volume packet logs can fill
`/tmp` quickly on busy links.

FakeSIP also suppresses ICMP/ICMPv6 time-exceeded replies used by hop-limit
probing. The packaged rules scope this suppression to the configured FakeSIP
interfaces; unrelated LAN or non-selected interfaces should not be globally
hijacked.

## Optional iptables Mode

The package depends on nftables because modern OpenWrt uses fw4/nft by default.
For old images that need iptables mode:

```sh
uci set fakesip.main.use_iptables='1'
uci commit fakesip
/etc/init.d/fakesip restart
```

Install the matching iptables/NFQUEUE kernel packages for your OpenWrt release
before enabling this mode.
