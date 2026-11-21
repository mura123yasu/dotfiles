---
title: guard.sh（PreToolUse）をフェイルセーフ化する（onFailure: "block"）
date: 2026-11-01
status: proposed
sources:
  - https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md (v2.1.295)
  - https://code.claude.com/docs/en/hooks
---

## 概要

`claude/settings.json` の PreToolUse フック（`guard.sh`）に、CHANGELOG v2.1.295 で追加された
`onFailure: "block"` を指定する。これにより、guard.sh が異常終了・タイムアウト・不正出力を
返した場合に「素通り」ではなく該当コマンドをブロックするようにする。

## 動機

- CHANGELOG v2.1.295 で command/http タイプの hook に `onFailure` オプションが追加された。
  デフォルト（現状の指定なし）では hook の起動失敗時に処理が続行される仕様。
- `guard.sh` は CLAUDE.md 冒頭の「main への直接 commit・push は禁止（PreToolUse hook でも
  強制される）」を実際に強制している唯一の機構であり、settings.json の deny ルールをすり抜ける
  変種を正規表現で捕捉する「最終防壁」として設計されている（guard.sh 冒頭コメント）。
- 現状の設定では、guard.sh 自体が（jq の不在、スクリプトのバグ、タイムアウト等で）異常終了した
  場合に危険コマンドがそのまま通過してしまう。これは「最終防壁」という設計意図と矛盾する
  フェイルオープンな挙動であり、フェイルセーフ（block）にすることで設計意図と実装を一致させられる。
- jq は Mac（Brewfile）・WSL（install.wsl.sh）の両方でインストール対象になっており、
  「jq 不在による誤ブロック」のリスクは低い。

## 変更内容

- `claude/settings.json` の `hooks.PreToolUse` の guard.sh エントリに `onFailure: "block"` を追加する
- 追加位置（hook オブジェクト単位か matcher グループ単位か）は実装時に公式ドキュメントで
  正確な配置を再確認する（SKILL.md の既存 Gotcha「settings.json の新キーは claude-code-guide
  で確認してから実装」に準拠）

## リスク・影響

- guard.sh が想定外の理由で頻繁に失敗するようになった場合、正当な Bash コマンドまで
  誤ってブロックされるようになる（現状のフェイルオープンでは失敗時に気づきにくいが、
  フェイルセーフ化後は失敗が「ブロック」として即座に表面化する点はむしろ利点）
- Mac と WSL で jq のバージョン・動作に差異がないか確認が必要（インストール自体は両 OS で
  担保されているが、バージョン差によるフラグ非対応等は未確認）
- ブロック時のエラーメッセージが「なぜ止まったか（guard.sh 自体の失敗 vs 危険コマンド判定）」を
  利用者が区別できるか、実装時に確認する
