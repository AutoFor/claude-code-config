---
name: gh-pr-approve
description: PR の承認・マージと後処理を行う。Codex MCP へ委譲。
disable-model-invocation: false
user-invocable: true
allowed-tools:
  - Bash
  - mcp__codex__codex
---

# GitHub PR 承認・マージスキル（Codex委譲版）

## 絶対禁止事項

`gh pr review --approve` は使用しないこと（自分の PR は GitHub の仕様上承認できない）。

## Step 1: コンテキスト収集（Claude Code が実行）

```bash
pwd
git branch --show-current
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
git remote get-url origin
git worktree list
gh pr list --head $(git branch --show-current) --state open --json number,isDraft,title
```

## Step 2: Codex へ委譲

Step 1 の結果を埋め込んで `mcp__codex__codex` を呼び出す。

`message` に以下を渡す（`<>` 内は Step 1 の実際の値で置換）:

---

```
作業ディレクトリ: <pwd>
現在ブランチ: <git branch --show-current>
デフォルトブランチ: <symbolic-ref 結果>
リポジトリ (owner/repo): <git remote get-url origin から抽出>
Worktree: <git worktree list の1行目パス。1行のみなら none>
オープン PR: <gh pr list の結果>

以下の手順を実行してください。

## 1. PR 番号の確定
オープン PR の情報から PR 番号を特定する。
PR が見つからない場合は「PR が見つかりません。」と表示して終了。

## 2. ブランチ名から Issue 番号を抽出する
git branch --show-current
issue-(\d+) パターンで抽出する。

## 3. GitHub App Bot で PR を承認する
bash ~/.claude/skills/gh-pr-approve/approve-pr.sh <owner> <repo> <PR番号>
403 エラーの場合は承認をスキップして次へ進む。

## 4. PR をマージする
gh pr merge <PR番号> --squash --repo <owner>/<repo>
gh pr view <PR番号> --repo <owner>/<repo> --json state,mergedAt

## 5. Issue クローズを確認する
gh issue view <Issue番号> --repo <owner>/<repo> --json state
CLOSED でない場合:
  gh issue close <Issue番号> --repo <owner>/<repo>

## 6. 後処理
bash ~/.claude/skills/gh-pr-approve/cleanup-after-merge.sh \
  <メインリポジトリパス> \
  <WorktreeパスまたはNone> \
  <デフォルトブランチ> \
  <ブランチ名>

## 完了報告
✅ PR のマージと後処理が完了しました。

完了した作業：
- PR #<N> を GitHub App Bot で承認
- PR #<N> をマージ
- Issue #<N> をクローズ
- <デフォルトブランチ> ブランチに切り替え・最新を取得
- ローカル・リモートブランチを削除
```
