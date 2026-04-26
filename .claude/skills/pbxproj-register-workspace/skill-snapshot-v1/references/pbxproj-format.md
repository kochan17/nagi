# nagi.xcodeproj/project.pbxproj 形式メモ

## 全体形式

- `objectVersion = 56`（Xcode 13 〜 14 互換）
- 文字列キーは **シングルクォート + 8 文字短縮 ID**: `'A1000050'`、`'B1000017'` など
- セクション境界: `/* Begin PBXFoo section */ ... /* End PBXFoo section */`

Xcode 15+ で導入された `PBXFileSystemSynchronizedRootGroup`（自動同期）は使われていない。各 source ファイルは `PBXBuildFile` + `PBXFileReference` + `PBXSourcesBuildPhase` の files リストの 3 箇所に手動登録される。

## 命名規約

| 接頭辞 | 用途 | 例 |
|---|---|---|
| `A1000NNN` | `PBXBuildFile`（コンパイル/リソースコピー対象） | `'A1000050'` |
| `B1000NNN` | `PBXFileReference`（ファイルメタデータ） | `'B1000050'` |
| `F1000NNN` | フェーズ・グループ・ターゲットなど構造ノード | `'F1000002'` (= PBXSourcesBuildPhase) |

新規 ID は `max(既存) + 1` で採番する。

## 重要 ID

| ID | 役割 |
|---|---|
| `F1000001` | PBXFrameworksBuildPhase |
| `F1000002` | **PBXSourcesBuildPhase** ← `.swift` / `.metal` の登録先 |
| `F1000003` | PBXResourcesBuildPhase ← `.wav` / `.jpg` 等の登録先（別 skill） |
| `F1000004` | PBXNativeTarget (nagi.app) |
| `F1000005` | PBXProject |

## 1 ファイル登録に必要な 3 箇所の挿入

### 1. PBXBuildFile セクション

```
'A1000098' /* WavesScene.swift in Sources */ = {isa = PBXBuildFile; fileRef = 'B1000098' /* WavesScene.swift */; };
```

### 2. PBXFileReference セクション

```
'B1000098' /* WavesScene.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = nagi/Scenes/Waves/WavesScene.swift; sourceTree = SOURCE_ROOT; };
```

`lastKnownFileType` の値:
- `.swift` → `sourcecode.swift`
- `.metal` → `sourcecode.metal`

### 3. PBXSourcesBuildPhase の files リスト

`F1000002` ブロックの `files = ( ... );` の中に **A ID** を追加:

```
'F1000002' = {
    isa = PBXSourcesBuildPhase;
    buildActionMask = 2147483647;
    files = (
        A1000001,
        A1000002,
        ...
        A1000098,    ← 追加
    );
    runOnlyForDeploymentPostprocessing = 0;
};
```

## 同期 group は使わない理由

`objectVersion = 56` のままにしているので、`PBXFileSystemSynchronizedRootGroup` は使えない。これを使うには `objectVersion = 70+` への migration が必要で、その場合 file ref ベースの既存エントリ全削除という大手術になる。**現状維持 + skill 登録**が圧倒的に低リスク。

## 既知の罠

- pbxproj Python ライブラリ（`pip install pbxproj`）は quoted short ID を誤認して NoneType エラーを吐く → 直接テキスト編集が必要
- インデントは **タブ文字**。スペース混入で Xcode が壊れる
- カンマの位置厳格。`files = ( A, B, C, );` のように末尾カンマ OK だが、要素間カンマ抜けは NG
- 終端の `};` の前のスペースも維持する
