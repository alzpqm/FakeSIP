# FakeSIP 上游 bug 稽核交接

後續完成：本文發現的 IPv6 options 問題已於同日 r23 修復、實機安裝及發布。
請先讀 `handoff-20260927-r23.md`；以下保留原始診斷時的狀態與證據，勿重做。

日期：2026-09-27（Asia/Taipei）；狀態：完成此輪診斷，確認一項仍影響 r22
的上游繼承缺陷，另確認兩類上游缺陷已被本分支修補。正式程式未修改。

## 範圍

- 使用者已更正目標：原始 FakeSIP 上游，不是 fakehttp。
- 對照上游與本分支，尋找可能由上游繼承並影響本專案的可重現 bug。
- 本輪為 bug 尋找／診斷，不預先修改正式程式、重啟路由器或發布版本。
- 使用既有本機工具及公開上游原始碼；不主動呼叫 Trusted Access 流程，
  不嘗試規避工具安全限制。測試僅限本機輸入或隔離 namespace。
- 不公開登入資料、實際端點、私人路徑；記錄證據、失敗及限制。
- 既有 dirty workspace 和未追蹤文件保持原樣，不 reset、不盲目提交。

## 操作紀錄

1. 在目標更正前，唯讀列出相鄰 fakehttp 檔案和 git status，並讀取前次
   FakeSIP runtime handoff。下一次讀取呼叫被使用者中止，無成功結果。
   未修改 fakehttp，未啟動測試或登入路由器；更正後停止該路線。
2. 現在核對 FakeSIP remote、套件 pin、README、既有回歸與可用 Linux 工具。
3. 從公開上游建立獨立 clone，`ls-remote` 核對 master 為
   `d4440ae146e5d9ecd1fa33b47661b4d8c7eb4641`（2025-07-30）。
   本分支正式基線為 `77f5c877911c8b0f7e0c1b14941921cd50416773`（r22），
   OpenWrt 原始碼 pin 為 `3dc98065e8f7f4a5e12b0e262af7dd45f1c90282`。
   忽略 CRLF 後，workspace 的 src/include 與乾淨 r22 clone 完全相同。
4. 兩邊是 source fork 關係，非執行時另依賴上游 daemon；上游的更新不會
   自動進入本分支。逐項對照 src/include 21 個差異檔，重點閱讀 packet、
   rawsend、NFQUEUE、process、signals、srcinfo、payload 和 firewall lifecycle。
5. 在獨立輸出目錄 fresh build 上游及 r22 ASan/UBSan 版本。沒有改正式源碼。
   新增實驗於 `docs/experiments/upstream-audit-20260927/`，僅在兩個新建
   network namespace 間用 veth、文件用 IPv6 位址及 queue 6514 進行。
6. r22 的六個 IPv6 options 實驗完成：plain 在 -0/-1 都有一個 decoy；
   Destination Options / Hop-by-Hop 在兩方向都沒有 decoy，各有兩次 parser
   rejection。所有原始 datagram/reply 均各一個、queue 無 backlog/drops、
   正常退出，無 sanitizer finding。屬功能失效，不是已證實崩潰。
7. 查 RFC 8200；rfc-editor 端回 429，改讀 IETF datatracker 的官方全文。
   最初一次跨目錄 `git diff` 呼叫方式無效，未採用其輸出；後續使用
   乾淨 clone 的 commit-to-commit diff 與 `diff -qr --strip-trailing-cr`。
8. 接著用同一組 packet fixture／既有 subprocess 回歸對照兩版，驗證上游
   殘留缺陷是否已被本分支阻隔。已完成：上游 UDP wire length 為 3/768，
   r22 均為正確 11；上游 subprocess 回歸在 broken-pipe 檢查 exit 1，
   r22 exit 0 並完成後面的 16 組 fd/logfile 測試。不要宣稱上游也跑完 16 組。
9. 再以 `ls-remote` 核對公開 fork master 仍為上述 r22 SHA，沒有遠端版本
   漂移。ShellCheck 初次提示編譯旗標的逗號及巢狀 trap 引號，已只調整
   實驗腳本的引號／cleanup 函式；不改正式源碼或編譯參數的語意。
10. ShellCheck 仍對刻意留給內層 namespace shell 展開的變數報 SC2016，
    加入局部且有原因的抑制註解；並非改為在主機 shell 提前展開。
    新增交接與實驗檔的私人識別／端點／token pattern 掃描零命中。
    使用者補充平台限制後維持原範圍，沒有切换模型、啟用其他存取流程
    或規避任何工具限制。
11. 最終 ShellCheck 與 bash syntax 檢查通過，再次執行六個隔離網路案例，
    結果與首次完全一致，重現腳本 exit 0（代表成功重現缺陷，不代表已修復）。
    `fork-ipv6-options-final.log` 與首次 log 的 SHA-256 相同。程序清單核對
    沒有殘留本輪的 fakesip／Python helper／peer sleep；新增檔案的匿名
    pattern 掃描仍為零命中。沒有將原始私人路徑 log 加入專案。
12. 收尾讀取狀態曾遇 Windows Git ownership 保護，改用僅限該指令的
    `safe.directory` 設定讀取，沒有修改全域 Git 設定；既有 dirty 檔保留。
    首次程序核對的 awk 欄位被外層 shell 展開而失敗，未採用該結果；
    改以直接讀取 WSL ps 並在 PowerShell 篩選，才確認 helper 數為零。

## 已確認仍影響本分支：IPv6 擴充標頭導致偽裝缺失

分類：P2／功能正確性，建議在下一次功能修復優先處理。不是本次已證實的
crash、記憶體破壞、原始 UDP 丟包或所有 IPv6 都失效。

- 位置：`src/ipv6pkt.c:57` 要求固定 IPv6 header 的 Next Header 直接為 UDP，
  並在第 67 行把 UDP header 固定在 40-byte IPv6 header 後面。
  這段 parser 與上游相同；本分支對此檔的既有修補只修改 builder。
- 但 `src/ipv6nft.c:163` 的 `meta l4proto udp` 規則會選入帶合法扩充標頭
  的 UDP。解析器遇到 Next Header 60／0 就拒絕。`src/nfqueue.c:181` 的
  fail-open 路徑保留原始封包，卻不再產生預期的 SIP decoy。
- 對照案例的 plain IPv6 UDP 在 -0/-1 都得到一個原包、一個回覆、一個
  decoy。加入 Destination Options 或 Hop-by-Hop（只含 PadN）後，兩個
  方向的原包與回覆仍各一個，decoy 為零，各觸發兩次 parser rejection。
- 使用 Linux kernel `sendmsg` 產生有效 UDP 與 checksum，並由另一 namespace
  的 UDP socket 正常接收，故不是僅依賴人工構造壞封包的假陽性。
- 已驗證所有 case queue backlog/kernel/user drops 為零、正常退出，無
  ASan/UBSan finding。`-s` 仍會留下這些解析 ERROR；未做高流量 log 壓測。
- 影響條件：流量帶這兩類 IPv6 extension header。未登入路由器或擷取
  使用者流量，不能宣稱實際 WAN 已出現此種流量，也不能用前次正常運行
  日誌排除此功能缺陷。

修復方向（尚未實作）：以有界長度檢查逐一解析可支援的 extension header，
定位 UDP offset；核對 IP／UDP 宣告長度與實際 buffer。Fragment、AH/ESP、
未知類型需有明確安全策略，不可盲目跳過。補上截斷、過長鏈、正常 options
及普通 UDP 的回歸，再跑 namespace case 並把 decoy 預期改為 1。

規範依據：[RFC 8200 §4](https://datatracker.ietf.org/doc/html/rfc8200#section-4)。
上游來源：[FakeSIP](https://github.com/MikeWang000000/FakeSIP/tree/d4440ae146e5d9ecd1fa33b47661b4d8c7eb4641)。

## 上游仍存在，但已不影響本分支的實測項目

| 項目 | 上游 d4440ae | 本分支 r22 | 本次證據 |
| --- | --- | --- | --- |
| IPv4/IPv6 UDP length | 3-byte payload 的 UDP length 是 3／768，應為 11 | 兩者均為 11 | 同一份 builder fixture |
| 子程序輸入中斷 | Broken pipe 後仍回報成功，回歸 exit 1 | 回報失敗，回歸 exit 0 | 既有 test_process；r22 也跑完 16 組 fd case |
| IPv6 options parser | Next Header 60／0 被拒絕 | 同樣被拒絕 | 兩版 parser fixture；r22 實際隔離網路再確認 |

先前 checksum-zero、NFQUEUE shutdown、快取與規則 rollback 修補，這次以
source diff 檢視而非再次完整重跑其歷史測試，不能冒稱本次全套驗證。
多程序共用 nft table 的限制已在 OpenWrt 文件明示，套件使用單一 main
instance；沒有把已知限制重新包裝成新發現。

## 重現與證據索引

- 可重現腳本與步驟：`docs/experiments/upstream-audit-20260927/README.md`。
  注意它們是目前缺陷的診斷 repro，部分 assertion 預期 bug 存在，不能
  直接當作修復後應通過的 acceptance tests。
- 私人 Linux 工作目錄為執行帳戶家目錄下 `fakesip-upstream-audit-20260927/`，
  含 `upstream/`、`upstream-build/`、`fork-build/`、build logs 及 `comparison/`。
  原始 sanitizer log 可能含本機編譯路徑，不要直接放到公開 release。
- `fork-ipv6-options.log` SHA-256：
  `cab2526d1b8e7197d627dee15a107b1aaa9a3bb232da65fc2955f0b8198e1195`。
- `comparison/upstream-packet-contracts.log` SHA-256：
  `2bbede32af905c13f49d25fbaa37a7ed761af0f082cbb808b8b663efce7c8e3e`。
- `comparison/fork-packet-contracts.log` SHA-256：
  `41137cc22343c070aff15d201402746cf6ed79dfc653ad4d430b39764544459e`。
- `comparison/upstream-process.log` SHA-256：
  `ee12ebe750cc71779cd3088334e1174cd694295f369bbb604d5bdf69d16590fa`。
- `comparison/fork-process.log` SHA-256：
  `c526c0aacf0c17ec944e567160e32123e6bd77898e1f3451e9bba82d2df16e8e`。

## 範圍限制與接手

- 此輪診斷已完成；IPv6 options 缺陷尚未修復／部署，不能標示為解決。
- 沒有修改正式 src/include、安裝路由器、建立 commit/tag、發布 release
  或向上游送 issue/PR。保留原本 dirty workspace，不提交無關檔案。
- 沒有遍歷所有協定／架構、壓力測試或無限制 fuzzing，也沒有證明「無其他 bug」。
- 下一步應針對已重現 parser 問題修補、把上述預期反轉並加入正式 regression，
  再按使用者授權進行實機與匿名發布；不用重新搜尋 credentials 或重做本輪。
