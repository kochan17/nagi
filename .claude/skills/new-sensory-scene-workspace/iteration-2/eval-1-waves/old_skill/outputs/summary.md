# Waves シーン追加 — eval-1-waves (old_skill, iteration-2)

`new-sensory-scene` skill v1 snapshot に従って Waves シーンを Bonfire と同じ品質レベルで実装した。

## テーマ

深い海の夜、月光が静かに揺れている雰囲気。深い indigo / midnight blue を主基調に、画面中央に淡い moonlight column が落ち、スパースな高周波 glitter と冷たい銀色の specular が波の頂上で瞬く。タッチした位置からは冷たい teal-blue の波紋が広がる。

## 8 ステップ実行結果

| Step | 内容 | 結果 |
|---|---|---|
| 1 | 既存パターン Read (BonfireScene / CampfireShader / TextureType / HapticEngine) | OK |
| 2 | nagi/Scenes/Waves/WavesScene.swift 作成 | OK (Bonfire を 1:1 写経 + tap/end/longPress に固有 haptic name を割当) |
| 3 | nagi/Shaders/WavesShader.metal を midnight ocean に書き換え | OK (kernel 名 waves_render 維持) |
| 4 | nagi/Models/TextureType.swift 更新 | OK (.waves の displayNameKey を誤キー .forBetterSleeping から .categoryWaves に修正、gradientColors を midnight ocean トーンに) |
| 5 | HapticEngine.swift に 3 factory 追加 | OK (makeWavesDropletTapPattern / makeWavesRippleTrainPattern / makeWavesDeepSwellPattern) |
| 6 | LocalizationManager.swift に .categoryWaves + 4 言語訳追加 | OK (en: Waves / ja: 波 / ko: 파도 / zh-Hans: 波浪) |
| 7 | RelaxView.destinationView(for:) を if/else から switch に refactor し .waves → SceneStage(scene: WavesScene()) 追加 | OK |
| 8 | pbxproj-register/scripts/register_one.py で WavesScene.swift と WavesShader.metal を登録 | OK (Scene.swift は新規、Shader.metal は silent orphan を heal: 既存 FileRef B1000044 に BuildFile + Sources phase を追加) |

## 触覚デザイン

シーン共通の releaseStyle = .ripple (HapticProfile.profile(for: .waves)) と整合させたうえで、シーン固有 3 パターンを追加:

- droplet_tap (began): 単発 transient、intensity 0.55 / sharpness 0.5 — 指が水面に触れた瞬間の冷たい点。
- ripple_train (ended): 3 連 transient (0.7 → 0.45 → 0.22)、間隔 0.13s / 0.15s — 波紋が外側に広がりながら減衰する律動。
- deep_swell (longPress, 700ms continuous): intensity curve 0.15 → 0.55 → 0.10 — ゆったりとしたうねりの起伏。Float(duration * 0.x) キャストで v1 の罠を回避。

## ビジュアルデザイン

WavesShader.metal を完全書き換え (旧版の caustics + ターコイズ teal は昼間の海 / プールで、深夜の海と噛み合わなかった):

- ベース: 縦グラデーション (horizon: 黒 → foreground: midnight navy) + 大スケール FBM の "海流" によるカラーブリージング
- うねり: 長周期 sin の重ね合わせ (waves_swell) + 2 つの環境リング (waves_ringHeight)
- ハイライト: 冷たい moon specular (lightDir 上 + 微小 tilt、tint (0.78, 0.85, 1.0))
- 月柱: 中央縦帯 × 高さ依存マスクの broad reflection
- きらめき: 高周波 noise を pow(14) でスパース化 + sin twinkle (waves_moonGlitter)
- タッチ反応: 冷たい teal-blue の inner glow + halo
- フォーム: 波の頂点に淡い灰白 (cresce) を控えめに

## 統合ポイント (Bonfire と同等の "完全シーン" 化)

- Relax タブのカード → 既存 banner UI で動作 (TextureType の gradientColors を midnight ocean 基調に変更したので、カード見た目も深夜の海色になる)
- カード tap → NavigationLink → SceneStage(WavesScene()) → FluidMetalView(.waves)
- SceneStage の task { scene.prepare(context:) } → 3 haptic pattern 登録 + ambient audio 登録 (asset 不在時は warning でスキップ)
- 触覚: 30ms バジェット内で発火するよう prepare() で事前ロード
- 音: waves_ocean.wav/aiff/m4a を bundle から探索 (skill ルール通り、無ければサイレントスキップ)

## 検証

- xcrun swiftc -parse nagi/Scenes/Waves/WavesScene.swift 通過
- xcrun metal -c nagi/Shaders/WavesShader.metal 通過
- pbxproj 4 サイト (BuildFile / FileRef / Group child / Sources phase) を WavesScene.swift / WavesShader.metal の両方について確認

## 副作用 / 既存動作への影響

- TextureType.waves.displayNameKey を変更したことで、これまで .waves カードに表示されていた "For your better sleeping" (誤キー由来) が "Waves" / "波" / "파도" / "波浪" の正しい表記になる。
- RelaxView の if/else → switch refactor は default ブランチで他カテゴリ全てを CategoryDetailView に流すため、既存挙動と等価。
- WavesShader.metal は silent orphan だった (FileRef のみで BuildFile 無し) ので、これまで .waves カードを開いても shader 由来のテクスチャは描画されていなかった。今回 register したことで初めて画面に出る。
