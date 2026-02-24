---
name: gh-worktree-branch
description: 新しい作業を開始するときに GitHub Issue を作成し、Git Worktree とブランチを作成する。Codex MCP へ委譲。
disable-model-invocation: false
user-invocable: true
allowed-tools:
  - Bash
  - mcp__codex__codex
---

# Git Worktree ブランチ作成スキル（Codex委譲版）

## 引数の処理

- **引数なし** (`/gh-worktree-branch`): 「作業内容を伝えてください」と表示して **停止する**
- **引数あり** (`/gh-worktree-branch ダークモード対応`): 以下のフローを実行する

## Step 1: コンテキスト収集（Claude Code が実行）

```bash
pwd
git remote get-url origin
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
git worktree list
```

## Step 2: Codex へ委譲

Step 1 の結果と引数を埋め込んで `mcp__codex__codex` を呼び出す。

`message` に以下を渡す（`<>` 内は実際の値で置換）:

---

```
作業ディレクトリ: <pwd>
リポジトリ (owner/repo): <git remote get-url origin から抽出>
デフォルトブランチ: <symbolic-ref 結果>
Worktree リスト: <git worktree list 結果>
Issue タイトル（引数）: <ユーザーの引数>

以下の手順を実行してください。

## 1. 古い Worktree の掃除
bash ~/.claude/skills/gh-pr-approve/cleanup-stale-worktrees.sh

## 2. GitHub Issue を作成する
gh issue create \
  --title "<Issue タイトル（引数をそのまま使用）>" \
  --body "<作業の概要>"

出力 URL から Issue 番号を記録する。

## 3. ブランチ名を生成する
Issue タイトルを英語スラッグに変換（小文字・ハイフン・3〜5語）。
ブランチ名: issue-<Issue番号>-<英語スラッグ>
例: issue-17-add-dark-mode

## 4. Worktree を作成する
bash ~/.claude/skills/gh-worktree-branch/create-worktree.sh <ブランチ名>

スクリプト出力のディレクトリパスを記録する。

## 5. 空コミットを作成して push する
cd <Worktree パス>
git commit --allow-empty -m "chore: start work on #<Issue番号>"
git push -u origin <ブランチ名>

## 6. Draft PR を作成する
gh pr create \
  --draft \
  --title "WIP: <Issueタイトル>" \
  --body "Closes #<Issue番号>

作業中..." \
  --head "<ブランチ名>" \
  --base "<デフォルトブランチ>"

## 7. クリップボードにコピーする
bash ~/.claude/skills/_shared/copy-to-clipboard.sh "cd <Worktreeの絶対パス> && claude"

## 完了報告
以下の形式で報告する（これ以上何も出力しない）:

処理が終了しました。

Issue: #<Issue番号> - <Issueタイトル>
ブランチ: <ブランチ名>
Draft PR: #<PR番号>

📋 クリップボードにコピー済み: cd <Worktreeの絶対パス> && claude
新しいターミナルで貼り付けて作業を開始してください。
```
