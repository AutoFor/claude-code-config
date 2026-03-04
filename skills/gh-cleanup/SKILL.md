---
name: gh-cleanup
description: 前回セッションで削除が遅延された stale worktree とブランチを一括削除する。
disable-model-invocation: true
user-invocable: true
allowed-tools:
  - Bash
---

# gh-cleanup スキル

前回セッションで削除が遅延された worktree・ブランチを削除する。

## 実行

```bash
bash ~/.claude/skills/gh-pr-approve/cleanup-stale-worktrees.sh
```

## 完了メッセージ

- 削除対象があった場合: スクリプト出力をそのまま表示
- 削除対象がなかった場合（出力なし）:「クリーンアップ対象はありませんでした。」と表示
