# MyApp

MyApp 是一款使用 SwiftUI 製作的奇幻冒險遊戲示範專案。玩家可以培養角色、抽取裝備與技能、進行戰鬥、釣魚、完成成就，並在遊戲中播放背景音樂。

## 主要功能

- 角色等級、攻擊力、生命值與爆擊能力成長
- 單抽、十連抽、稀有度機率與七星保底機制
- 裝備穿戴、升級、分解及隨機屬性
- 技能抽取、裝備與升級系統
- 戰鬥、生命值、傷害提示及動畫效果
- 釣魚、踩地雷與成就系統
- 金幣、寶石、魚及技能點等資源管理
- 背景音樂切換、循環播放及遊戲音效
- 帳號資料匯出與轉移碼匯入

## 使用技術

- Swift
- SwiftUI
- Observation（`@Observable`）
- AVFoundation
- AudioToolbox
- Codable
- UserDefaults

## 開發環境

- macOS
- Xcode
- iOS Simulator 或實體 iPhone

## 執行方式

1. Clone 此儲存庫：

   ```bash
   git clone https://github.com/b15902134/Aurora-Expedition.git
   ```

2. 使用 Xcode 開啟 `0.xcodeproj`。
3. 選擇 iOS Simulator 或已連接的 iPhone。
4. 按下 Xcode 的 Run 按鈕，或使用快捷鍵 `Command + R`。

## 專案結構

```text
MyApp/
├── 0.xcodeproj/             Xcode 專案設定
├── MyApp/
│   ├── Assets.xcassets/     圖片與 App Icon
│   ├── ContentView.swift    遊戲資料、邏輯及主要畫面
│   ├── MyApp.swift          App 進入點
│   ├── Info.plist           App 設定
│   └── *.xcstrings          本地化字串
└── README.md
```

## 核心設計

專案使用 `GameStore` 集中管理角色、貨幣、裝備、技能及抽卡狀態。`GameStore` 採用 `@Observable`，資料變動時 SwiftUI 會自動更新相關畫面。

抽卡系統包含基礎機率、軟保底及第 80 抽必得七星裝備的機制。每件裝備和技能均使用 UUID 識別，以便正確處理穿戴、升級、分解及帳號資料轉移。

## 注意事項

- 商店購買目前為示範流程，尚未串接正式 StoreKit 交易。
- 帳號轉移使用本機編碼資料，尚未串接後端伺服器。
- 專案包含音樂、字型及第三方美術素材；公開散布或商業使用前，請確認各素材的授權條款。
