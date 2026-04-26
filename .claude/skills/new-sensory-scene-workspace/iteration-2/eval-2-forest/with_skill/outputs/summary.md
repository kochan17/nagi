# Forest シーン追加 — 完了サマリー

`new-sensory-scene` skill の 9 ステップ手順に沿って、Forest シーンを既存の Bonfire と同じ構造で追加した。

## テーマ

> 深い古い森、葉のざわめき、木漏れ日が差し込むような視覚と、踏みしめる落ち葉のような触覚。

## ファイル変更

### 新規作成 (2)

| Path | 行数 | 役割 |
|---|---|---|
| `nagi/Scenes/Forest/ForestScene.swift` | 109 | `SensoryScene` 実装 / `ForestTouchState` / `ForestVisual` |
| `nagi/Shaders/ForestShader.metal` | 372 | `forest_render` カーネル（procedural） |

### 編集 (5)

| Path | 変更内容 |
|---|---|
| `nagi/Models/TextureType.swift` | `case forest` 追加。6 メソッド分岐（kernelName / displayNameKey / iconName(`leaf.fill`) / materialTextureName(nil) / soundFileName(`forest_ambient`) / gradientColors(深緑→苔緑→若葉緑)）すべてに対応。 |
| `nagi/Services/HapticEngine.swift` | `HapticProfile.profile(for:)` に `.forest` を追加（intensity 0.55 / sharpness 0.75 / `.snap`）。`makeForestLeafCrunchPattern` / `makeForestTwigSnapPattern` / `makeForestLeafRustlePattern` の 3 つの static factory を追加。`Float(...)` キャストの罠も回避済み。 |
| `nagi/Services/LocalizationManager.swift` | `L10nKey.categoryForest` を追加。4 言語辞書（en/ja/ko/zh-Hans）に "Forest" / "森" / "숲" / "森林" を追加。 |
| `nagi/Views/Relax/RelaxView.swift` | `destinationView(for:)` を `if/else` から `switch` にリファクタし、`.forest → SceneStage(scene: ForestScene())` を追加。 |
| `nagi.xcodeproj/project.pbxproj` | `register_one.py` で 2 ファイル登録（FileRef B1000104/B1000105、BuildFile A1000104/A1000105、Sources phase）。 |

## ビジュアル設計（ForestShader.metal）

10 レイヤー構成で深い森を再現:

1. 大気深度 — 床（冷たい緑）→ 中層（霞んだ苔色）→ 早朝の温かい光のグラデーション
2. 遠景の木 — 4 本の細い幹、青みがかった低コントラストの樹皮（atmospheric perspective）
3. 中景の木 — 3 本の太い幹、詳細な樹皮の年輪 + 苔の斑点 + キャノピー陰
4. 森の床 — 落ち葉、湿った苔、camera 近くを暗く落とす
5. キャノピー（3 層パララックス） — back/mid/near、Voronoi セルでリーフクラスター、breeze で揺れる
6. 木漏れ日 (god rays) — 右上の太陽方向に指向性あり、葉の隙間（gap）でゲート、床に光だまり
7. 浮遊するダスト — 18 粒のホコリが光のシャフト内でだけ可視化
8. タッチ反応 — 局所的な leaf rustle ノイズ + 温かい手の glow halo
9. 大気霧 — 中距離の青緑霧で奥行き
10. ビネット + ACES tonemap + tint — 共通フィニッシュ

## 触覚設計（HapticEngine の 3 factory）

| パターン | トリガ | 設計 |
|---|---|---|
| `leaf_crunch` | `.began`（最初の足音） | 3 トランジェントを 0/0.025/0.06s で重ねたマイクロクラスター。乾いた葉が一足で複数破れる質感 |
| `twig_snap` | `.longPress` | 単発の鋭い強い transient（intensity 0.95 / sharpness 1.0）。床の奥の小枝が折れる |
| `leaf_rustle` | `.ended` | duration 0.55s の continuous + パラメータカーブで 0.40 → 0.22 → 0.05 にフェード。葉が落ち着いていく余韻 |

## skill チェック項目

- [x] Step 0 命名衝突チェック（`forest` は TextureType に未存在 → OK）
- [x] Step 1 Bonfire を完全 Read してパターン把握
- [x] Step 2 ForestScene.swift（テンプレ→固有実装）
- [x] Step 3 ForestShader.metal（kernel 名 `forest_render` を TextureType.kernelName と一致）
- [x] Step 4 TextureType の 6 メソッド分岐すべて埋めた
- [x] Step 5 HapticEngine.profile + 3 factory + Float キャスト
- [x] Step 6 LocalizationManager の L10nKey + 4 言語辞書すべて
- [x] Step 7 RelaxView を switch にリファクタして `.forest` 分岐追加
- [x] Step 8 pbxproj 登録 2 ファイル（Sources phase）

## 既存コードへの影響

純粋な追加変更。既存 Bonfire / 他のテクスチャには一切手を加えていない。

## 次の確認 (任意)

- iOS シミュレータで Relax タブ → Forest カードが表示されるか
- カードタップで SceneStage に遷移するか
- 触覚パターンを実機で確認（Core Haptics は simulator 不可）
- `forest_ambient.wav` を `Resources/` に追加すれば PHASE 経由で森のアンビエントが鳴る（現状は warning ログだけで silent skip）
