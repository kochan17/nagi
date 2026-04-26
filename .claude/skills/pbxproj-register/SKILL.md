---
name: pbxproj-register
description: nagi の旧式 pbxproj (objectVersion 56・quoted short ID) に新規 Swift/Metal ファイルを登録し、Xcode build target に確実に入れて silent orphan 化を防ぐ skill。Claude が `nagi/` 配下に新規 `.swift` または `.metal` を Write した直後は必ずこの skill を呼ぶこと。「Xcode に追加」「pbxproj 登録」「ファイル追加した」「ビルドに入れて」「silent orphan」「シェーダーが効かない」「シーン作って」「new file」「add to target」など、Xcode プロジェクトへのファイル組み込みを示唆する文脈すべてで発動する。新規ファイル作成後は確認なしでも先んじて提案すること。Sources phase 専用（音源・画像などの Resources は対象外）。
---

# pbxproj-register

## なぜこの skill が存在するか

nagi の `nagi.xcodeproj/project.pbxproj` は **objectVersion = 56** の旧式形式で、`PBXFileSystemSynchronizedRootGroup`（Xcode 15+ の自動同期）を使っていません。新規ファイルを `nagi/` 配下に置いただけでは Xcode のビルドターゲットに入らず、**コンパイラはスキップして警告も出さない**状態（silent orphan）になります。

Xcode build target に**実際に**入れるには **4 箇所**への登録が必要:

| サイト | 役割 | 抜けるとどうなる |
|---|---|---|
| `PBXBuildFile` | コンパイル対象として登録 | コンパイル対象に入らない |
| `PBXFileReference` | ファイルメタデータ | 他の登録から参照不可 |
| `PBXSourcesBuildPhase` (F1000002) | ビルドフェーズの files リスト | コンパイル対象に入らない |
| `PBXGroup` 親グループの children | Project Navigator 表示 | Xcode 左サイドバーに出ない（ビルドは通るが UX 破綻） |

**毎回手動で 4 箇所を登録する**ことが正しい運用であり、それを skill 化したのがこれです。

## 適用範囲

| 対象 | 対象外 |
|---|---|
| `nagi/**/*.swift` | ルート外（`scripts/`、`.claude/`、ドキュメント） |
| `nagi/**/*.metal` | `.wav`、`.mp3`、`.jpg`、`.png` などのリソース（**Resources phase**用は別 skill `phase-audio-asset` で扱う） |

複数ファイルを一度に渡された場合は順次処理して構いません。

## 引数

```
/pbxproj-register <path1> [path2] [path3] ...
```

- パスは **repo root からの相対パス**を推奨（例: `nagi/Scenes/Waves/WavesScene.swift`）
- 絶対パスを渡された場合はスクリプトが自動的に repo root（cwd 起点）からの相対パスに変換する
- 末尾の改行・余分な引用符は無視

## 手順

### Step 1: 入力前提を確認

各 path について以下を確認してから次へ:

1. ディスクに**実在する**こと（`ls <path>`）
2. 拡張子が `.swift` または `.metal` であること
3. `nagi/` 配下にあること

これらは `register_one.py` の `validate()` も再チェックするので二重ガードになる。

### Step 2: 登録実行

skill 同梱の `scripts/register_one.py` を呼ぶ:

```bash
python3 .claude/skills/pbxproj-register/scripts/register_one.py <path1> [path2] ...
```

スクリプトの動作:

- **REPO root を cwd 起点で解決**する（スクリプトの `__file__` 起点ではない）。worktree でも正しく動く
- 各 path について **4 サイトの存在を構造的に検査**（filename grep ではなく、FileRef → BuildFile → Sources → Group の参照を辿る）
- 完全登録済み → `ok <path> (already complete: ...)` で skip
- 一部欠けている → 欠けている分だけを追加（既存 ID は再利用、orphan healing）
- 未登録 → 4 サイト全部に新規挿入（PBXGroup は `nagi/<segment>/<segment>/` の階層に従って自動作成）

### Step 3: 検証（軽量 grep）

スクリプトの出力に `+ <path>  (FileRef BNNN, BuildFile ANNN, Sources phase, Group ENNN)` が出れば成功。

念のため最終 grep で確認したい場合は:

```bash
# 4 サイト確認
grep -n "<filename>" nagi.xcodeproj/project.pbxproj
```

期待: PBXBuildFile・PBXFileReference・親 Group・Sources phase の 4 行ヒット。

### Step 4: 結果サマリー

ユーザーに報告:

```
✅ 登録完了
- nagi/Scenes/Waves/WavesScene.swift  (FileRef B1000104, BuildFile A1000104, Sources phase, Group E1000100)

⏭️  既登録 (skip)
- nagi/Scenes/Bonfire/BonfireScene.swift  (already complete)

次のビルドから target に入ります。
```

ユーザーが build 検証を要求した場合のみ `ios-dev:xbm-build` を呼ぶ。デフォルトでは呼ばない（ビルドは重い）。

## やってはいけないこと

- **手動で pbxproj を編集しない**。インデント・改行・終端カンマの規約が壊れて他のツールが死にます
- **`scripts/add_to_pbxproj_text.py`（リポジトリの batch 用）を編集して呼ばない**。あれは初期セットアップ用。skill が呼ぶのは `.claude/skills/pbxproj-register/scripts/register_one.py`
- **既存 PBXFileReference を削除して再登録しない**。orphan healing は欠けているサイトを**追加**するだけで、既存 ID は保持する
- **Resources phase に登録しようとしない**。`.wav` などは別 skill 案件
- **build 検証を勝手に走らせない**。重い（30 秒〜）ので、ユーザーが明示要求した時だけ `ios-dev:xbm-build` を呼ぶ

## トラブルシュート

| 症状 | 原因 | 対処 |
|---|---|---|
| `could not locate nagi.xcodeproj/project.pbxproj` | cwd が repo 外 | `cd <repo-root>` してから再実行 |
| `could not locate PBXSourcesBuildPhase F1000002` | pbxproj が手動編集で壊れている | `git diff` で改変を確認、必要なら revert |
| 採番が衝突する（A ID 重複） | スクリプト並列実行 | 並列起動しない。1 ターン 1 呼び出し |
| `could not locate PBXGroup 'E1000002'` | nagi root group ID が変更された | `references/pbxproj-format.md` を更新、スクリプトの `NAGI_ROOT_GROUP_ID` 定数も合わせる |

## 参考

- `scripts/add_to_pbxproj_text.py`（リポジトリ root の方）— batch 版の元実装。pbxproj の構造詳細はここのコメントが詳しい
- `references/pbxproj-format.md` — quoted short ID 方式の構造解説（必要時に Read）

## バージョン履歴

- **v2** (現行): 4 サイト対応 (PBXGroup 自動作成)、構造的 orphan 検知、cwd 起点の repo 解決
- v1: 3 サイト対応 (PBXGroup 抜け)、filename grep 検知、`__file__` 起点の repo 解決 → worktree で破綻
