# nagi — Claude 向け前提

iOS / SwiftUI のマルチセンサリー・マインドフルアプリ。`SPEC.md` と `DESIGN.md` と合わせて読む。

## スタック（確定）

- **UI**: SwiftUI（`.layerEffect` / `.colorEffect` / `.distortionEffect`、iOS 17+）
- **GPU**: Metal（既存 `nagi/Shaders/*.metal`、`MTKView` via `UIViewRepresentable`）
- **触覚**: Core Haptics（`CHHapticPattern`）
- **空間オーディオ**: PHASE（`PHASEEngine`）+ AVAudioEngine（環境音ミックス）
- **ターゲット**: iPhone 15 Pro（A17 Pro / ProMotion 120Hz）を第一実機、iOS 17+

## 採用しない技術と理由

- **RealityKit / RealityView**: 使わない。3D モデル（USDZ）を最低限にする方針なので、3D シーン基盤の旨味が無い。純 SwiftUI + Metal 2D で完結。
- **Blender / 動画焼き込み**: 使わない。procedural Metal シェーダーでリアルタイム描画する（動的性 > 写実度のトレードオフで動的性を選ぶ）。
- **Unity / Flutter / React Native**: 使わない。Core Haptics と PHASE の精度が落ちる。
- **USDZ 3D アセット**: 原則使わない。薪・石・地面は 2D procedural シェーダーで描く。

## 設計の背骨（Sensory spine）

音・触覚・映像を常に 30ms 以内で同期させることが本プロダクトの核。これを保証するため `nagi/Sensory/` に下記を置く:

- `SensoryScene` プロトコル — 各自然シーンが conform
- `SceneStage` — 視覚 / 音 / 触覚を composition
- `SyncClock` — 30ms 同期の計測・保証
- `HapticEngine` — Core Haptics ラッパ
- `SpatialAudioEngine` — PHASE + AVAudioEngine bridge
- `TouchReactor` — gesture → 各エンジンへ fanout
- `RenderBudget` — 熱・fps 監視、MetalFX 切替

シーン実装は `nagi/Scenes/<Name>/<Name>Scene.swift` に集約。共有 90% / シーン固有 10% を狙う。

## ディレクトリ規約

```
nagi/
  App/       - エントリ、AppState、RootView
  Views/     - 画面単位（Home/Breath/Relax/Sleep/Onboarding/Paywall/Profile）
  Shaders/   - Metal シェーダー（1 効果 = 1 ファイル、Shaders サフィックス）
  Sensory/   - Sensory spine（protocol + 各 engine） 新設
  Scenes/    - 自然シーン実装（Bonfire/Waves/Forest/...）  新設
  Studio/    - Debug ビルド限定のチューニング UI（A/B 比較、HUD、hot reload）新設
  Models/
  Services/
  ViewModels/
  Resources/
```

## Xcode プロジェクト運用

- `nagi.xcodeproj/project.pbxproj` は **旧式 file ref 方式**（`objectVersion = 56`、synchronized groups 未使用）
- 新規 `.swift` / `.metal` を追加したら **必ず pbxproj にも登録する**。放置すると silent orphan ファイルになる（既存 `.metal` 5 個が実際そうなっている）
- 自動化ヘルパ: `scripts/add_to_xcodeproj.py`（`pbxproj` Python ライブラリ使用）
- 基本: `python3 scripts/add_to_xcodeproj.py <path/to/file> [--group Sensory]` で追加

## パフォーマンス前提

- **120fps を狙う**（ProMotion）。60fps は劣化許容値
- 長時間セッション（10〜30 分）前提。`RenderBudget` が熱・バッテリーを監視し、閾値超えたら MetalFX upscaling に切替
- **デフォルトで非アクティブ時のシェーダー更新頻度を下げる**（無入力 10 秒で 30fps 化、1 分で 15fps 化）

## 同期の契約（Sensory 三位一体）

タッチ→反応の目標レイテンシ:
- 視覚: ≤ 50ms（Metal uniform 即時反映）
- 触覚: ≤ 30ms（Core Haptics 事前ロード済みパターン）
- 音: ≤ 50ms（PHASE 事前ロード済みイベント）

3 者のズレは `SyncClock` で測り、20ms 超えたらログ警告、30ms 超えたら自動 fallback。

## ビルド・テスト

- Debug ビルドでは `Studio` タブが出て、スライダ/A-B/hot reload/HUD が使える
- Release ビルドでは `Studio` は完全に消える（`#if DEBUG` と Target Membership で分離）
- テスト実行は XcodeBuildMCP の `ios-dev:*` サブエージェント経由

## やらないこと

- 抽象宇宙・トンネル・RGB 分離系のビジュアル（瞑想体験と噛み合わない）
- MVP / PoC / v1 としての妥協。最初から ship 品質で作る
- 機能追加の勝手判断。大きな設計判断は必ずユーザーに確認
