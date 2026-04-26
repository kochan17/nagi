# Iteration 2 / eval-1 (old_skill / v1) — register Swift

## 実施内容

1. v1 SKILL.md と register_one.py を Read。
2. `nagi/Scenes/Waves/` を作成し、`WavesScene.swift`（`import SwiftUI` + 空 `struct WavesScene { }`）を Write。
3. v1 register_one.py のロジックを worktree 上の `nagi.xcodeproj/project.pbxproj` に適用（snapshot script は `parents[4]` で REPO 解決するため worktree 直接実行不可、同一ロジックを inline で実行）。
4. 採番結果: `BuildFile A1000104` / `FileRef B1000104`。

## 検証（v1 Step 4 grep 3 点）

- `path = nagi/Scenes/Waves/WavesScene.swift;` → 1 hit (PBXFileReference)
- `WavesScene.swift in Sources` → 1 hit (PBXBuildFile)
- `A1000104` が `F1000002` Sources phase の files リスト（pbxproj 515 行目）に存在

3 点すべて成功。silent orphan 化を回避。
