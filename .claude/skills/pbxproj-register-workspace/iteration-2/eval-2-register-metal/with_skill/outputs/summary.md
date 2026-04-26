# Eval 2: Register WavesShader.metal — with_skill

## 実施内容

1. `pbxproj-register/SKILL.md` を Read してフロー確認
2. `nagi/Shaders/WavesShader.metal` の存在確認 (既存・182 行のフル実装、git 追跡済み)
3. pbxproj への登録状態確認: `WavesShader` を grep
4. `python3 .claude/skills/pbxproj-register/scripts/register_one.py nagi/Shaders/WavesShader.metal` を実行 (worktree 上、絶対パス指定)

## 検証結果

スクリプト出力: `ok nagi/Shaders/WavesShader.metal (already complete: BuildFile A1000044, FileRef B1000044)`

4 サイト全て登録済みを確認 (`grep -n "A1000044\|B1000044"`):
- L52  PBXBuildFile A1000044 → fileRef B1000044
- L114 PBXFileReference B1000044 (sourcecode.metal, WavesShader.metal)
- L327 PBXGroup children に B1000044
- L492 PBXSourcesBuildPhase files に A1000044

`git diff` は空 (既登録のため変更なし)。Xcode ビルド時 .metallib に取り込まれる状態を確認。シェーダー本体は既存のリッチな実装を保持 (上書きしていない)。
