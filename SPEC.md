# Pindrop — 產品規格書 v0.4

> 最後更新：2026-04-10

---

## 產品概述

iOS App，讓用戶從 Instagram 短片一鍵跳轉到 Google Maps 對應的餐廳頁面。
核心價值：**零摩擦**，不需要手動搜尋，一個分享動作完成。

---

## 技術棧

| 項目 | 規格 |
|------|------|
| 平台 | iOS 17+ |
| 開發語言 | Swift / SwiftUI |
| 資料持久化 | SwiftData |
| AI 解析 | Groq API（llama-4-scout-17b，OG metadata 輸入） |
| 本地快速解析 | LocalParser（Regex，優先於 AI，不消耗 API 配額） |
| 地點搜尋 | Google Places API Text Search（取得 place_id） |
| 地圖跳轉 | Google Maps Universal Links（`https://www.google.com/maps/search/`） |
| 切入點 | iOS Share Extension |

---

## 核心流程

```
用戶在 IG 看到餐廳短片
  → 點「分享」→ 選擇 Pindrop
  → Share Extension 啟動（bottom sheet 呈現，dim 遮罩覆蓋 IG）
  → 爬取 IG 頁面 OG metadata（og:title、og:description）
  → Step 2a：LocalParser 快速解析（Regex，零 API 成本）
      ┌─ 成功 → 直接進 Step 3
      └─ 失敗 → Step 2b：Groq API 解析（llama-4-scout）
  → 用解析結果（可能多間）呼叫 Google Places API 搜尋
      ┌─ 單一結果 → 顯示確認畫面
      ├─ 多個結果 → 顯示選擇清單
      └─ 無結果   → 顯示錯誤畫面
  → 用戶確認 / 選擇
  → 用 place_id 跳轉 Google Maps 該店家頁面（並記錄至過往記錄）
```

---

## Share Extension UI

### 呈現方式

底部 sheet 模擬（自製，非 system sheet）：
- 全螢幕透明容器，上方半透明黑色遮罩（點擊 → 取消）
- 下方白色圓角 panel（grabber handle）
- Loading / 確認 / 錯誤：panel 高度 = 螢幕 1/3
- 多餐廳選擇：panel 高度動態增長（最高 80% 螢幕）

### Loading
- Spinner + 文字「正在尋找餐廳...」

### 確認畫面（單一結果）
- Header：「取消」｜「找到餐廳」
- 餐廳名稱 + 地址（row 格式）
- 右側 inline「地圖」按鈕 → 跳轉 Google Maps
- 底部「儲存至清單」按鈕

### 選擇清單（多個結果）
- Header：「取消」｜「選擇餐廳」
- 列出候選店家（名稱 + 地址 + 右側「地圖」按鈕），最多顯示 5 筆
- Checkbox 多選
- 底部「儲存至清單」按鈕（需先選取）

### 錯誤畫面
- 圖示 + 錯誤訊息
- 副文字：建議用戶自行在 Google Maps 搜尋

---

## 主 App（Container App）

Tab 結構（3 個 tab）：

### 過往記錄
- 顯示曾透過 Share Extension 點「地圖」的餐廳列表
- 每筆記錄顯示：名稱、地址、開啟時間
- Row 操作：「儲存」（存至清單）、「地圖」（重新開啟）
- 支援左滑刪除

### 清單
- 使用者自建的餐廳收藏清單
- 可從 Share Extension 或過往記錄儲存
- 支援多個清單，每個清單有名稱
- 支援左滑刪除清單

### 使用說明
- 教學步驟圖示（在 IG 點分享 → 選 Pindrop → 自動跳轉）
- 提示用戶需先安裝 Google Maps

---

## AI 解析策略

### Step 1：LocalParser（優先）

Regex 快速解析，識別台灣常見 IG 美食貼文格式：
- `【店名】` 格式
- `📍 / 🚩` 後接地址

成功率：格式化貼文約 60-70%，節省 API 配額。

### Step 2：Groq API（Fallback）

**輸入：** `og:title` + `og:description`

**模型：** `meta-llama/llama-4-scout-17b-16e-instruct`

**Prompt 目標：**
- 抽取所有餐廳名稱（繁體中文 / 英文）
- 抽取地點提示（城市、地區、地址，如有）
- 支援多間餐廳（最多 10 間）
- 輸出格式：`{ "restaurants": [{ "name": "...", "location": "..." }] }`

**降級處理：**
- OG metadata 無法取得 → 顯示錯誤畫面
- API 無法解析出餐廳名稱 → 顯示錯誤畫面
- API 配額超限（HTTP 429） → 顯示錯誤畫面

---

## Google Places API 搜尋策略

1. 用 `name + location` 組合查詢 Text Search
2. 取回候選結果（name、formatted_address、place_id）
3. 結果 ≥ 2 筆 → 顯示選擇清單
4. 結果 = 1 筆 → 顯示確認畫面
5. 結果 = 0 筆 → 顯示錯誤畫面

**多間餐廳情境（Groq 解析出多間）：**
- 並行搜尋所有餐廳，每間取最佳一筆
- 結果整合後走同一套 0/1/多 邏輯

---

## Google Maps 跳轉

使用 Universal Links（自動判斷是否安裝 App）：

```
https://www.google.com/maps/search/?api=1&query=<name>&query_place_id=<place_id>
```

已安裝 Google Maps → 直接開啟 App
未安裝 → Safari 開啟網頁版 Google Maps

---

## 資料模型

### HistoryEntry（SwiftData）
- `placeId: String`
- `name: String`
- `address: String`
- `openedAt: Date`

### RestaurantList（SwiftData）
- `name: String`
- `createdAt: Date`
- `items: [RestaurantItem]`

### RestaurantItem（SwiftData）
- `placeId: String`
- `name: String`
- `address: String`
- `list: RestaurantList`（relationship）

---

## MVP 範圍

### 已實作
- iOS Share Extension（bottom sheet 自製呈現）
- IG URL OG metadata 擷取
- LocalParser 本地快速解析
- Groq API 解析（支援單間 / 多間餐廳）
- Google Places API 搜尋
- Google Maps Universal Links 跳轉
- 過往記錄
- 餐廳清單（收藏）
- 主 App（三 Tab：過往記錄 / 清單 / 使用說明）

### 不包含（未來版本）
- Android 版本
- 用戶帳號系統
- 訂閱 / Paywall

---

## 已知技術風險

| 風險 | 說明 | 對策 |
|------|------|------|
| IG 反爬蟲 | OG metadata 可能被擋 | 先實測；若失敗考慮用 IG oEmbed API |
| Groq 解析準確率 | 影片描述若無餐廳名稱則無法解析 | LocalParser 先行；清楚顯示錯誤，不靜默失敗 |
| Groq API 配額 | 免費額度有限 | LocalParser 降低 API 呼叫量 |
| Share Extension 高度 | iOS 不允許外部控制 sheet 高度 | 自製 bottom sheet（透明背景 + dim overlay） |

