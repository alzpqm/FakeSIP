# FakeSIP OpenWrt r22

OpenWrt 25+ APK release for x86_64. Install both synchronized `0.9.1-r22`
packages with `apk add --allow-untrusted`; existing UCI settings are preserved.
Older OpenWrt versions and other architectures remain source-build targets.

- Fix computed-zero UDP checksum encoding for IPv4 and IPv6.
- Fix subprocess input failures when standard file descriptors are closed.
- Add exhaustive checksum, descriptor and isolated IPv4/IPv6 runtime regressions.
- Verify with sanitizers, GCC analyzer, firewall rollback tests, package/LuCI
  tests, and an actual OpenWrt 25.12.5 upgrade and target-native regressions.
- Redact residual private identifiers from the release snapshot, including
  encoded handoffs. Published historical Git objects are unchanged.

## 正體中文

- 修正 UDP 校驗和剛好為零時的封包格式，涵蓋 IPv4 與 IPv6。
- 修正標準輸入輸出被關閉時，子程序管線失效的問題。
- 通過 131,076 組封包、16 種檔案描述符組合，以及隔離網路啟停測試。
- 已在 OpenWrt 25.12.5 實機升級驗證，保留原有設定。
- 發布內容僅有核心 APK、LuCI APK 與 `SHA256SUMS`，不含登入資料或備份。

Short validation windows found no crashes or queue drops; this is not a claim
of long-duration or throughput testing. See the r22 audit document for scope.
