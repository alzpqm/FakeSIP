# FakeSIP OpenWrt r23

OpenWrt 25+ APK release for x86_64. Install both synchronized `0.9.1-r23`
packages with `apk add --allow-untrusted`; existing UCI settings are preserved.

- Fix missing SIP decoys for IPv6 UDP with Hop-by-Hop or Destination Options.
- Bound extension traversal to 16 headers and validate IPv6/UDP declared lengths.
  Unsupported headers (including Fragment, Routing, AH and ESP), jumbograms and
  malformed packets remain on the unchanged-original-packet fail-open path.
- Add 157 parser boundary cases and six real IPv6 send/receive acceptance cases.
- Preserve existing checksum and subprocess fixes; no unrelated configuration changes.

## 正體中文

- 修正 IPv6 合法擴充標頭造成 SIP 偽裝封包缺失。
- 加入長度與標頭鏈界線檢查；不支援的封包仍放行原包。
- OpenWrt 25.12.5 實機已升級核心與 LuCI，原有設定保留。
- 發布僅含兩個 APK 與 `SHA256SUMS`，不包含登入資料、備份或原始設備日誌。

Validation: sanitizer core regressions, GCC analyzer, ten IPv4/IPv6 lifecycle
cycles, six isolated IPv6 options cases, and OpenWrt package/LuCI checks passed
on Debian. The router passed 157 native parser cases and 131,076 packet checksum
cases before upgrade; installed file hashes match the release APKs. A 120-second
production window observed a stable process, advancing traffic counters and
zero queue backlog/kernel/userspace drops, with unchanged UCI settings.

The router lacks veth support, so the isolated extension wire tests ran on
Debian, not on the router. Live-router observation is a short acceptance window,
not a long-duration or throughput guarantee. See the r23 handoff for evidence.
