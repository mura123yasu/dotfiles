---
title: syncClaudeAiSkills / syncClaudeAiPlugins を明示的に無効化し、ハーネスの再現性を守る
date: 2026-10-01
status: proposed
sources:
  - https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md（v2.1.275）
  - https://code.claude.com/docs/en/settings
---

## 概要

`claude/settings.json` に `"syncClaudeAiSkills": false` と `"syncClaudeAiPlugins": false`
を追加し、claude.ai アカウント側で有効化されたスキル・プラグインが端末セッションへ
自動同期される挙動を明示的にオフにする。

## 動機

- v2.1.275 で、claude.ai アカウントで有効なスキル・プラグインを端末セッションにも
  自動同期する機能が追加された。`syncClaudeAiSkills` / `syncClaudeAiPlugins` を
  `false` にすると、ユーザー設定レベルで強制的にオフにできる
- 本リポジトリは「ハーネス（skills/agents/hooks/rules/settings）はすべて dotfiles で
  バージョン管理し、Mac/WSL 双方へ install スクリプトで展開する」という再現性を
  前提に設計されている（CLAUDE.md の「マルチリポジトリ統合管理」節、
  `install.sh` / `install.wsl.sh` の存在がその証左）
- claude.ai 側のアカウント同期は、この dotfiles 管理の外側でスキル・プラグインが
  端末に増減する経路になる。具体的には: (1) 本リポジトリの `dotfiles-drift-check` /
  `github-push` / `harness-improve` と名前が衝突するスキルがアカウント側に追加された
  場合の予期しない上書き・併存、(2) 端末によって有効なアカウント側スキルが異なる場合に
  「同じリポジトリの同じコミットなのに端末ごとに挙動が違う」状態が生まれうる点
- 現状 `claude/settings.json` にこの2キーの明示的な設定はなく、将来の既定値変更に
  挙動が左右される

## 変更内容

- `claude/settings.json` のトップレベルに `"syncClaudeAiSkills": false` と
  `"syncClaudeAiPlugins": false` を追加
- `harness/README.md` のディレクトリ構成表の近くに、ハーネスの再現性方針
  （スキル・プラグインは dotfiles 経由でのみ導入する）として一言注記する

## リスク・影響

- claude.ai アカウント側で便利に使っていたスキル・プラグインがある場合、端末セッションで
  見えなくなる（オプトイン導線を自分で選べていたものが一律オフになる）。
  必要なものは本リポジトリの `claude/skills/` に明示的に移植する運用にする
- 設定ファイル1行の追加のみで、既存の hooks・permissions・sandbox 設定には影響しない
- 両 OS 共用ファイル（`claude/settings.json`）の変更のみで、install スクリプトへの影響なし
