# Pindrop — Claude Code Orchestrator 說明

這份文件說明如何在這個專案中使用多 Agent 系統。

## 專案概述

Pindrop 是一款 iOS App，讓用戶從 Instagram 短片一鍵跳轉到 Google Maps 對應的餐廳頁面。
詳細規格請參考 `SPEC.md`。

## Agent 系統

所有 Agent prompt 位於 `.claude/agents/`：

| Agent | 檔案 | 負責範圍 |
|-------|------|---------|
| PM | `agents/pm.md` | 需求定義、PRD、優先順序、Roadmap |
| Dev | `agents/dev.md` | Swift/SwiftUI 開發、API 串接、架構 |
| UIUX | `agents/uiux.md` | UI 設計、SwiftUI layout、HIG 審查 |
| QA | `agents/qa.md` | 測試案例、XCTest、Bug 回報 |
| DevOps | `agents/devops.md` | App Store 上架、CI/CD、憑證管理 |
| Marketing | `agents/marketing.md` | ASO、文案、社群行銷、上市計畫 |

## 如何使用

### 單一 Agent（指定角色）

```bash
# 請 Dev agent 分析程式碼
claude --system-prompt "$(cat .claude/agents/dev.md)" -p "請審查 Sources/ShareExtension/ 的程式碼架構"

# 請 QA agent 寫測試
claude --system-prompt "$(cat .claude/agents/qa.md)" -p "幫 LocalParser 寫完整的 XCTest 測試"

# 請 DevOps agent 說明上架流程
claude --system-prompt "$(cat .claude/agents/devops.md)" -p "說明 Pindrop 第一次上架 App Store 的完整步驟"
```

### 多 Agent 並行（Orchestrator 模式）

在 Claude Code 互動模式中，你可以指示 Claude 同時 spawn 多個 agent：

```
請同時進行以下工作：
1. 用 Dev agent 分析 LocalParser 的現有實作
2. 用 QA agent 設計 LocalParser 的測試案例
3. 用 PM agent 評估是否需要支援更多 IG 貼文格式
```

Claude Code 會使用 Task tool 並行執行，各 agent 獨立運作後整合結果。

### 互動模式中切換角色

進入 Claude Code 後，直接說：

```
你現在是 Dev agent，請讀取 .claude/agents/dev.md 作為你的角色設定...
```

## 常見工作流程

### 新功能開發

```
1. PM agent → 寫 user story + acceptance criteria
2. UIUX agent → 設計 UI 方案
3. Dev agent → 實作程式碼
4. QA agent → 寫測試 + 找 edge case
5. DevOps agent → 確認不影響上架流程
```

### Bug 修復

```
1. QA agent → 確認重現步驟，分析根本原因
2. Dev agent → 修復程式碼
3. QA agent → 驗證修復，補充迴歸測試
```

### 準備上架

```
1. DevOps agent → 上架清單確認
2. Marketing agent → ASO 文案、截圖策略
3. QA agent → 最終 smoke test 清單
```
