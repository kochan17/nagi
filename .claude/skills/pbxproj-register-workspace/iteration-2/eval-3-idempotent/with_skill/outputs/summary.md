# BonfireScene 登録 — 冪等性確認サマリー

## タスク

`nagi/Scenes/Bonfire/BonfireScene.swift` を Xcode のビルドターゲットに登録する。

## 事前確認結果（既に登録済みかどうか）

**結論: 既に 4 サイト全て登録済み**だった。

事前 `grep "BonfireScene"` で確認した既存登録（`/tmp/pbxproj_before.txt` 起点）:

| サイト | ID | 行 |
|---|---|---|
| `PBXBuildFile` | `A1000098` | line 62 |
| `PBXFileReference` | `B1000098` | line 124 |
| `PBXGroup` (Bonfire / `E1000032`) の children | `B1000098` を含む | line 379 |
| `PBXSourcesBuildPhase` (`F1000002`) の files | `A1000098` を含む | (build phase 内) |

## skill 実行結果

`python3 .claude/skills/pbxproj-register/scripts/register_one.py nagi/Scenes/Bonfire/BonfireScene.swift` を実行。

スクリプト出力:

```
ok nagi/Scenes/Bonfire/BonfireScene.swift  (already complete: BuildFile A1000098, FileRef B1000098)

wrote nagi.xcodeproj/project.pbxproj
```

`already complete` と判定され、新規挿入は skip された。

## 重複登録は起きたか

**起きていない（完全に冪等）**。

検証方法: 実行前に `nagi.xcodeproj/project.pbxproj` を `/tmp/pbxproj_before.txt` にコピーし、スクリプト実行後に `diff` を取った。

```
$ diff /tmp/pbxproj_before.txt nagi.xcodeproj/project.pbxproj
$ echo $?
0
```

差分ゼロ。スクリプトは pbxproj を再書き出ししているが、内容は完全に同一。`PBXBuildFile` / `PBXFileReference` / `PBXGroup children` / `Sources phase files` のいずれにも重複エントリは追加されなかった。

## 結論

pbxproj-register skill は冪等。既登録ファイルに対して再実行しても 4 サイトのいずれにも重複エントリを生まず、既存 ID を保持する。`pbxproj_after.diff` は空ファイル。
