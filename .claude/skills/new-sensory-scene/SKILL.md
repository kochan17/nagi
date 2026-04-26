---
name: new-sensory-scene
description: nagi に新しい sensory シーン（Waves / Forest / Waterfall / Snow など、Bonfire と同じ品質レベルの procedural Metal シーン）を追加するための完全チェックリスト skill。「シーン作って」「scene 追加」「Waves やりたい」「Forest シーン」「new sensory scene」「滝のシーン」「焚き火みたいな新しいやつ」など、新規シーン追加を示唆する文脈すべてで発動する。Bonfire 1 個しか前例が無い段階で 8 ステップに散らばる編集箇所（SensoryScene 実装・Metal シェーダー・TextureType・Localizable・HapticEngine・RelaxView・pbxproj 登録）を抜けなく実行するため、新シーン追加要求があれば必ずこの skill を起動すること。
---

# new-sensory-scene

## なぜこの skill が存在するか

新シーン追加は**8 ファイルにまたがる構造的変更**で、抜けがあるとビルドが通っても**シーンが Relax タブに出ない**、**触覚が無音になる**、**Studio で出てこない**などの silent failure になる。Bonfire 1 個分しか前例が無いので、毎回手作業で 8 箇所を辿るのは事故の元。この skill は、各箇所を**順序通りに**、**抜けなく**、**既存パターンに従って**埋めるための骨格を提供する。

視覚・音・触覚の**美的判断は agent / ユーザーに委ねる**。skill は構造のみ。

## 引数

```
/new-sensory-scene <SceneName> [<theme description>]
```

- `<SceneName>`: PascalCase、英単語 1 つ推奨（`Waves`、`Forest`、`Waterfall`、`Snow`）
- `<theme description>`（任意）: 1〜2 行のムード指示（「夜の海、月光、深い静寂」など）。シェーダー stub と gradient を agent が判断する材料

skill 内では以下の表記で呼び分ける:
- `__SCENE__` = PascalCase（例: `Waves`）
- `__scene__` = lowercase（例: `waves`）

## 手順（9 ステップ）

### Step 0: 命名衝突チェック（**必ず最初に**）

`nagi/Models/TextureType.swift` を grep して、提案された `__scene__` がすでに `enum TextureType` に存在しないか確認:

```bash
grep -n "case __scene__" nagi/Models/TextureType.swift
```

ヒットした場合（例: `Waves` を頼まれたが `.waves` がすでに存在）、ユーザーに必ず確認:

> 「`.waves` はすでに variant カタログ用に予約済みです。新シーン用に差別化された名前（例: `MoonlitWaves` / `OceanWaves` / `DeepSea`）を使うか、既存の `.waves` を sensory シーン化するかどちらにしますか？」

**確認なしに勝手にリネームしない**。ユーザーの命名意図を尊重する。`MoonlitWaves` のような複合名で進めることが決まったら、以降の `__SCENE__` / `__scene__` をそれに置換する。

### Step 1: 既存パターンを Read で確認

新シーンは BonfireScene を**1:1 で写経して固有部分を差し替える**のが正解。先に下記を Read しておく:

- `nagi/Scenes/Bonfire/BonfireScene.swift` — SensoryScene 実装の完全形
- `nagi/Shaders/CampfireShader.metal` — procedural Metal シェーダーの完全形
- `nagi/Models/TextureType.swift` — `.campfire` case 周りの 6 メソッド分岐
- `nagi/Services/HapticEngine.swift` の `HapticProfile.profile(for:)` と `makeCampfireSmallCracklePattern` 等の static factory（ファイル末尾）

これを skip すると 90% の確率でパターンを外す。

### Step 2: Scene 実装を作成

skill 同梱テンプレを使う:

```bash
mkdir -p nagi/Scenes/__SCENE__/
cp .claude/skills/new-sensory-scene/templates/Scene.swift.template nagi/Scenes/__SCENE__/__SCENE__Scene.swift
sed -i '' 's/__SCENE__/<SceneName>/g; s/__scene__/<scenename>/g' nagi/Scenes/__SCENE__/__SCENE__Scene.swift
```

※ macOS の `sed` は `-i ''` 必須。Linux ではない。

テンプレ内の TODO コメント 3 箇所を埋める:
- `prepare()` 内: 触覚パターン登録（Step 5 で作る factory を呼ぶ）+ 音源登録
- `onTouch()` の `.began`、`.ended`、`.longPress` 内: `context.haptics.play(name: ...)` を Step 5 のパターン名に合わせる

### Step 3: Metal シェーダーを作成

```bash
cp .claude/skills/new-sensory-scene/templates/Shader.metal.template nagi/Shaders/__SCENE__Shader.metal
sed -i '' 's/__SCENE__/<SceneName>/g; s/__scene__/<scenename>/g' nagi/Shaders/__SCENE__Shader.metal
```

テンプレは FBM ノイズ + tint で塗る最小実装。ユーザーが渡した theme description に応じて kernel 関数の中身を差し替える。例:
- 海: 横方向 sin 波 + ガウス減衰の波頭ハイライト
- 森: 縦方向の細長い木型 + 葉のざわめき FBM
- 滝: 縦方向に流れる FBM + 飛沫パーティクル

**kernel 関数名は必ず `__scene___render`（例: `waves_render`）にする。** TextureType.kernelName と一致させないと FluidMetalView がパイプラインを見つけられない。

### Step 4: TextureType に case 追加

`nagi/Models/TextureType.swift` の以下を編集:

1. `enum TextureType` 本体に `case __scene__` を追加
2. 6 メソッドの switch 文に case を追加:
   - `kernelName`: `"__scene___render"`
   - `displayNameKey`: `.category__SCENE__`（次の Step 5 で `L10nKey` に追加する key）
   - `iconName`: SF Symbol 名（`water.waves` など適切なもの）
   - `materialTextureName`: 通常 `nil`（procedural shader のため）
   - `soundFileName`: `"__scene___ambient"`
   - `gradientColors`: Relax タブのカードに使う 2〜3 色のグラデーション

**注意**: `needsFluidSim` は default の `false` で良いので、追加不要（既存 `default: return false` が拾う）。

### Step 5: HapticEngine に case + factory 追加

`nagi/Services/HapticEngine.swift` を編集:

1. `HapticProfile.profile(for:)` の switch に case 追加:
   ```swift
   case .__scene__:
       return HapticProfile(baseIntensity: <0.0-1.0>, baseSharpness: <0.0-1.0>, releaseStyle: .<bounce|snap|fade|ripple>)
   ```
   既存の選び方:
   - `bounce`: 弾力（slime）
   - `snap`: 鋭い単発 + ソフト残響（particles, campfire）
   - `fade`: 長い余韻（fluids, orbs）
   - `ripple`: 連続する減衰タップ（waves, kaleidoscope）

2. ファイル末尾近くに、シーン固有の static factory を 1〜3 個追加。例（`makeCampfireSmallCracklePattern` のパターンを写経）:
   ```swift
   static func make__SCENE__SmallTapPattern() throws -> CHHapticPattern {
       let event = CHHapticEvent(
           eventType: .hapticTransient,
           parameters: [
               CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
               CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6),
           ],
           relativeTime: 0
       )
       return try CHHapticPattern(events: [event], parameters: [])
   }
   ```
   **長さ系（continuous）パターンの parameterCurves で `value: TimeInterval × Float` を計算する場合、必ず `Float(...)` でキャストする**（v1 で踏んだ罠）。

3. Step 2 で書いた `__SCENE__Scene.prepare()` から、これらの factory を呼んで `context.haptics.register(name:pattern:)` する。

### Step 6: LocalizationManager の dict + L10nKey に display name 追加

**`Localizable.xcstrings` は実体が使われていない**。実際の翻訳ソースは `nagi/Services/LocalizationManager.swift` のハードコード辞書。xcstrings は触らない（壊すと Xcode が起動しなくなる）。

`nagi/Services/LocalizationManager.swift` を編集:

1. `enum L10nKey: String` の `case categoryCampfire` 周辺に新 case を追加:
   ```swift
   case category__SCENE__
   ```

2. 4 言語の翻訳辞書（`enTranslations`、`jaTranslations`、`koTranslations`、`zhTranslations` など）すべてに `.categoryCampfire: "Campfire",` のすぐ近くに新エントリを追加:
   ```swift
   .category__SCENE__: "<英語>",   // enTranslations
   .category__SCENE__: "<日本語>", // jaTranslations
   .category__SCENE__: "<한국어>", // koTranslations
   .category__SCENE__: "<中文>",   // zhTranslations
   ```

3. Step 4 の `displayNameKey` で参照する key 名（`.category__SCENE__`）と一致していることを確認。

### Step 7: RelaxView の navigation を分岐

`nagi/Views/Relax/RelaxView.swift` の `destinationView(for:)`:

```swift
@ViewBuilder
private func destinationView(for category: TextureType) -> some View {
    switch category {
    case .campfire:
        SceneStage(scene: BonfireScene())
    case .__scene__:
        SceneStage(scene: __SCENE__Scene())
    default:
        CategoryDetailView(category: category)
    }
}
```

既存が `if/else` 形式なら `switch` にリファクタする方が拡張しやすい（Bonfire 1 個の段階では `if/else` だが、3 個目から `switch` 一択）。

### Step 8: pbxproj に新規ファイルを登録

新規 `.swift` と `.metal` を pbxproj に登録する。これは `pbxproj-register` skill の責務:

```bash
python3 .claude/skills/pbxproj-register/scripts/register_one.py \
  nagi/Scenes/__SCENE__/__SCENE__Scene.swift \
  nagi/Shaders/__SCENE__Shader.metal
```

成功すれば `+ <path>  (FileRef ..., BuildFile ..., Sources phase, Group ...)` が 2 行出る。

## 完了報告フォーマット

ユーザーへの最終報告:

```
✅ __SCENE__ シーンを追加しました

作成: 2 ファイル
- nagi/Scenes/__SCENE__/__SCENE__Scene.swift
- nagi/Shaders/__SCENE__Shader.metal

編集: 4 ファイル
- nagi/Models/TextureType.swift (.__scene__ case 追加)
- nagi/Services/HapticEngine.swift (HapticProfile + factory)
- nagi/Resources/Localizable.xcstrings (display name)
- nagi/Views/Relax/RelaxView.swift (navigation 分岐)

pbxproj 登録: 2 ファイル ([BuildFile/FileRef ID])

次の確認 (任意):
- iOS シミュレータで Relax タブ → __SCENE__ カードが出るか
- カード tap で SceneStage に遷移するか
- 触覚パターンを調整したければ HapticEngine.swift の make__SCENE__... を編集
- シェーダーを調整したければ nagi/Shaders/__SCENE__Shader.metal の kernel を編集
```

## やってはいけないこと

- **Bonfire / Campfire を Read せずにテンプレを埋める**。固有実装の細かい慣習（Logger subsystem 名、`_render` サフィックス、`previousTouchLocation` の reset 順序など）を必ず外す
- **Step 4-7 を 1 ファイルずつ commit する**。8 ステップは**一気通貫**で 1 commit。途中で止めるとビルドが壊れた中間状態になる
- **Studio タブへのパラメータ追加を勝手にやる**。それは別 skill（`studio-tuning-add`）の責務。混ぜると skill が肥大化する
- **音源 .wav を勝手に生成・ダウンロードする**。`prepare()` のテンプレは「音源が無ければ skip」になっているので、音源アセットは別途ユーザー判断
- **既存シーン（Bonfire）に手を加える**。新シーン追加は純粋な追加変更で、既存コードに触らない

## トラブルシュート

| 症状 | 原因 | 対処 |
|---|---|---|
| ビルドエラー `Cannot find type '__SCENE__Scene'` | pbxproj 登録忘れ | Step 8 を再実行 |
| Relax カードに出ない | `TextureType` への case 追加忘れ | Step 4 を見直し |
| カード tap しても古い CategoryDetailView | RelaxView 分岐忘れ | Step 7 を見直し |
| Metal pipeline lookup failed | kernel 名と `kernelName` 不一致 | Step 3 と Step 4 の `__scene___render` を比較 |
| Display name が出ない / 「未翻訳」が出る | LocalizationManager.swift の dict 4 言語のいずれかに追加忘れ | Step 6 を見直し、4 言語全部に追加されているか確認 |
| `.category__SCENE__` が type-check を通らない | L10nKey enum への case 追加忘れ | Step 6 の (1) を見直し |

## 同梱ファイル

- `templates/Scene.swift.template` — Step 2 で使用
- `templates/Shader.metal.template` — Step 3 で使用

## バージョン履歴

- **v2** (現行):
  - Step 0 追加（命名衝突チェック）
  - Step 6 を `Localizable.xcstrings` 編集 → `LocalizationManager.swift` の dict + L10nKey 編集に修正（xcstrings は実装で使われていない）
- v1: 8 ステップ初版。命名衝突対応無し、Step 6 が xcstrings 誤指示
