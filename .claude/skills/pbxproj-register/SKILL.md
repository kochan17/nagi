---
name: pbxproj-register
description: nagi の旧式 pbxproj (objectVersion 56・quoted short ID) に新規 Swift/Metal ファイルを登録し、Xcode build target に確実に入れて silent orphan 化を防ぐ skill。Claude が `nagi/` 配下に新規 `.swift` または `.metal` を Write した直後は必ずこの skill を呼ぶこと。「Xcode に追加」「pbxproj 登録」「ファイル追加した」「ビルドに入れて」「silent orphan」「シェーダーが効かない」「シーン作って」「new file」「add to target」など、Xcode プロジェクトへのファイル組み込みを示唆する文脈すべてで発動する。既に 5 個の orphan `.metal` が放置されている前科があるため、新規ファイル作成後は確認なしでも先んじて提案すること。Sources phase 専用（音源・画像などの Resources は対象外）。
---

# pbxproj-register

## なぜこの skill が存在するか

nagi の `nagi.xcodeproj/project.pbxproj` は **objectVersion = 56** の旧式形式で、`synchronized groups`（Xcode 15+ の自動ファイル同期）を使っていません。新規ファイルを `nagi/` 配下に置いただけでは Xcode のビルドターゲットに入らず、**コンパイラはスキップして警告も出さない**状態（silent orphan）になります。

実際にこのリポジトリには 5 個の `.metal` ファイル（FractalShader, KaleidoscopeShader, OrbsShader, ParticlesShader, SlimeShader, WavesShader）が orphan として放置されています。**毎回手動で pbxproj に登録する**ことが正しい運用であり、それを skill 化したのがこれです。

## 適用範囲

| 対象 | 対象外 |
|---|---|
| `nagi/**/*.swift` | ルート外（`scripts/`、`.claude/`、ドキュメント） |
| `nagi/**/*.metal` | `.wav`、`.mp3`、`.jpg`、`.png` などのリソース（**Resources phase**用は別 skill `phase-audio-asset` で扱う） |
| | テスト target（現在テスト無し。将来追加時は別途検討） |

複数ファイルを一度に渡された場合は順次処理して構いません。

## 引数

```
/pbxproj-register <path1> [path2] [path3] ...
```

- パスは **repo root からの相対パス**（例: `nagi/Scenes/Waves/WavesScene.swift`）
- 絶対パスを渡された場合は `/Users/kotaishida/projects/personal/nagi/` プレフィックスを除去して相対化する

## 手順

### Step 1: 入力検証

各 path について以下を確認:

1. ディスクに**実在する**こと（`ls <path>` で確認）。存在しなければエラーで停止
2. 拡張子が `.swift` または `.metal` であること。それ以外なら「Sources phase 対象外、skip」と報告
3. `nagi/` 配下にあること。それ以外なら「対象外、skip」と報告

### Step 2: 重複チェック

```bash
grep -c "path = $(basename <path>);" nagi.xcodeproj/project.pbxproj
```

結果が 1 以上なら**すでに登録済み**。skip して「already registered」と報告（冪等性）。

### Step 3: 登録実行

skill 同梱の `scripts/register_one.py` を呼ぶ:

```bash
python3 .claude/skills/pbxproj-register/scripts/register_one.py <path1> [path2] ...
```

スクリプトは:
- 次の利用可能な `A1000NNN` / `B1000NNN` ID を採番
- `PBXBuildFile`、`PBXFileReference`、`PBXSourcesBuildPhase (F1000002)` の files リストにエントリを挿入
- 既存ファイルは自動 skip（重複防止の二重ガード）
- 出力に `+ <path>  (BuildFile A1000NNN, FileRef B1000NNN)` を表示

### Step 4: 検証（軽量 grep）

各 path について以下 3 点を確認:

```bash
# 1. PBXFileReference に入っているか
grep "path = <path>;" nagi.xcodeproj/project.pbxproj

# 2. PBXBuildFile に入っているか（filename 一致）
grep "<filename> in Sources" nagi.xcodeproj/project.pbxproj

# 3. Sources phase の files リストに ID が入っているか（採番された A ID で）
# register_one.py の出力から A ID を抽出して grep
```

3 点すべてヒットすれば成功。1 つでも欠ければエラー報告。

### Step 5: 結果サマリー

ユーザーに報告するフォーマット:

```
✅ 登録完了
- nagi/Scenes/Waves/WavesScene.swift  (BuildFile A1000098, FileRef B1000098)
- nagi/Shaders/WavesShader.metal      (BuildFile A1000099, FileRef B1000099)

⏭️  既登録 (skip)
- nagi/Scenes/Bonfire/BonfireScene.swift

次のビルドから target に入ります。確認したい場合は `ios-dev:xbm-build` で symbol 解決を検証してください。
```

## やってはいけないこと

- **手動で pbxproj を編集しない**。インデント・改行・終端カンマの規約が壊れて他のツールが死にます
- **`add_to_pbxproj_text.py` の FILES_TO_ADD を編集しない**。あれは batch maintenance 用で skill から触ると衝突します
- **Resources phase に登録しようとしない**。`.wav` などは別 skill 案件
- **build 検証を勝手に走らせない**。重い（30 秒〜）ので、ユーザーが `--verify-build` 指定したか明示要求した時だけ `ios-dev:xbm-build` を呼ぶ

## トラブルシュート

| 症状 | 原因 | 対処 |
|---|---|---|
| `register_one.py` が「could not locate F1000002」エラー | pbxproj が壊れている / Sources phase の ID が変わった | git diff で pbxproj の手動編集の有無を確認、必要なら revert |
| 採番が衝突する（A ID 重複） | スクリプト並列実行 | 並列起動しない。1 ターン 1 呼び出し |
| grep 検証で files リストに無い | Sources phase 挿入が失敗 | スクリプトの正規表現マッチを確認、`scripts/add_to_pbxproj_text.py` のソースを参照 |

## 参考

- `scripts/add_to_pbxproj_text.py` — batch 版の元実装。pbxproj の構造詳細はここのコメントが詳しい
- `references/pbxproj-format.md` — quoted short ID 方式の構造解説（必要時に Read）
