# Forest シーン追加 — old_skill (v1) ベースライン

## 使用したスキル

`/Users/kotaishida/projects/personal/nagi/.claude/skills/new-sensory-scene-workspace/skill-snapshot-v1/SKILL.md` (v1) を 8 ステップ通りに実行。worktree 内 `.claude/skills/new-sensory-scene/SKILL.md` (v2) は無視。

## テーマ解釈

「深い古い森、葉のざわめき、木漏れ日が差し込むような視覚と、踏みしめる落ち葉のような触覚」を:

- 視覚: 多層 trunk (遠景 4 + 中景 3 + 前景 1)、canopy leaf-cluster 14 個、斜め god-rays + 漂う dust mote、地面の薄い fog
- 触覚: `leaf_crunch` (短い 3 連 transient で乾いた葉のクシャ感)、`twig_snap` (長押し用の鋭い枝折れ)、`leaf_scatter` (リリース時の落ち葉の散らばり; continuous + 3 transient)
- 音: `forest_ambient` を bundle に予約 (アセット未配置でも skip するパターン踏襲)

## 完了した 8 ステップ

| Step | 内容 | 結果 |
|---|---|---|
| 1 | 既存 BonfireScene / CampfireShader / TextureType / HapticEngine を Read | 完了 |
| 2 | `nagi/Scenes/Forest/ForestScene.swift` 作成 (Bonfire 写経 + Forest 固有差分) | 完了 |
| 3 | `nagi/Shaders/ForestShader.metal` 作成 (`forest_render` kernel、procedural 多層森) | 完了 |
| 4 | `TextureType.swift` に `.forest` case + 6 メソッド分岐追加 | 完了 |
| 5 | `HapticEngine.swift` に `HapticProfile` case + 3 つの static factory 追加 | 完了 |
| 6 | `LocalizationManager.swift` に `categoryForest` key と en/ja/ko/zh-Hans 翻訳 | 完了 |
| 7 | `RelaxView.swift` の `destinationView(for:)` を `if/else` → `switch` にリファクタしつつ `.forest → ForestScene()` 分岐追加 | 完了 |
| 8 | `pbxproj-register` skill 経由で 2 ファイル登録 (FileRef B1000104/B1000105、BuildFile A1000104/A1000105) | 完了 |

## 作成 / 編集ファイル

**作成 (2)**:
- `nagi/Scenes/Forest/ForestScene.swift`
- `nagi/Shaders/ForestShader.metal`

**編集 (5)**:
- `nagi/Models/TextureType.swift` (`.forest` case + 6 メソッドに分岐)
- `nagi/Services/HapticEngine.swift` (`HapticProfile.profile(for:)` + 3 factory)
- `nagi/Services/LocalizationManager.swift` (`categoryForest` enum + 4 言語)
- `nagi/Views/Relax/RelaxView.swift` (switch リファクタ + `.forest` 分岐)
- `nagi.xcodeproj/project.pbxproj` (Step 8 自動更新)

## v1 skill 評価メモ

- **テンプレ写経 + sed 置換**は機能した。Bonfire を起点にする前提が固まっているので 2 ファイル目以降の構造的迷いは少ない。
- **kernel 名の `__scene___render` 一致ルール**は明文化されていて、`forest_render` を間違える余地が無かった。
- **HapticEngine の TimeInterval × Float キャスト罠**が SKILL.md 内で明記されており、`Float(duration * 0.7)` を最初から書けた。
- **v1 の Step 6 は xcstrings JSON 直接編集を推奨しているが、実プロジェクトでは `LocalizationManager.swift` が source of truth** で xcstrings はほぼ stale orphan のみ。今回は実態に合わせて LocalizationManager を更新した (xcstrings 破損リスクを避けた)。**v2 で Step 6 の判断基準を明示するべき**。
- **Step 7 は `if/else` → `switch` リファクタ提案が SKILL.md 内に書かれていたので素直に追従**できた。3 件目以降必須。
- **Step 8 の pbxproj-register 連携**は 1 行で完了。silent orphan を踏まずに済んだ。
- **触覚の意匠 (踏みしめる落ち葉)** に対しては、SKILL.md には触覚パターンの引き出しが「bounce / snap / fade / ripple」の 4 種だけ示されているが、Forest の場合は "snap" 系で 3 連 transient を組むのが自然と判断できた。テーマ → release style の対応表があると判断速度が上がる。

## ビルド確認

このタスクではビルドは未実行 (worktree 隔離 + skill 効果計測の baseline 作成のため)。

## 想定されるリスク

- `forest_ambient.wav` は bundle に存在しない。`prepare()` 内で skip するのでクラッシュはしないが Studio で「音が出ない」と気づかれる可能性。
- `tree.fill` は SF Symbols 4+。iOS 17+ ターゲットなので問題無い。
