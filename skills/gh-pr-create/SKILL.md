---
name: gh-pr-create
description: 作業完了時に GitHub PR を作成・承認・マージまで実行する。Codex MCP へ委譲。
disable-model-invocation: false
user-invocable: true
allowed-tools:
  - Bash
  - mcp__codex__codex
---

# GitHub PR 作成スキル（Codex委譲版）

## Step 1: コンテキスト収集（Claude Code が実行）

```bash
pwd
git branch --show-current
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
git remote get-url origin
git status --short
git worktree list
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
変更ファイル: <git status --short>

以下の手順を実行してください。

## 0. コミットとプッシュ
git status --short で未コミット変更を確認。
変更がある場合、ファイルをテーマでグループ化してコミット（Conventional Commits 形式、日本語）:
  git add <ファイル> ...
  git commit -m "<type>: <日本語説明>"
git push -u origin <現在ブランチ名>

## 1. ブランチ名から Issue 番号を抽出する
git branch --show-current
issue-(\d+) パターンで抽出する。
見つからない場合は「ブランチ名から Issue 番号を検出できませんでした。」と表示して終了。

## 2. 既存 Draft PR を確認する
gh pr list --head <現在ブランチ名> --state open --json number,isDraft,title

### Draft PR あり → 2A へ
gh api repos/<owner>/<repo>/pulls/<PR番号> -X PATCH \
  -f title="<WIP プレフィックスを除いたタイトル>" \
  -f body="Closes #<Issue番号>

<変更内容の詳細>"
gh pr ready <PR番号>

### Draft PR なし → 2B へ
gh pr create \
  --title "<タイトル>" \
  --body "Closes #<Issue番号>

<変更内容の詳細>"

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
- PR #<N> を作成・マージ
- Issue #<N> をクローズ
- <デフォルトブランチ> ブランチに切り替え・最新を取得
- ローカル・リモートブランチを削除
```
