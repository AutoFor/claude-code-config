---
name: gh-worktree-from-issue
description: 既存の GitHub Issue から Git Worktree を使った作業ブランチを作成する。Codex MCP へ委譲。
disable-model-invocation: false
user-invocable: true
allowed-tools:
  - Bash
  - mcp__codex__codex
---

# Git Worktree from Issue スキル（Codex委譲版）

## Step 1: コンテキスト収集（Claude Code が実行）

```bash
pwd
git remote get-url origin
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
git worktree list
```

Issue 番号が引数で指定された場合:
```bash
gh issue view <Issue番号> --json number,title,labels
```

Issue 番号が指定されない場合:
```bash
gh issue list --state open --json number,title,labels --limit 20
```

## Step 2: Codex へ委譲

Step 1 の結果を埋め込んで `mcp__codex__codex` を呼び出す。

`message` に以下を渡す（`<>` 内は実際の値で置換）:

---

```
作業ディレクトリ: <pwd>
リポジトリ (owner/repo): <git remote get-url origin から抽出>
デフォルトブランチ: <symbolic-ref 結果>
Worktree リスト: <git worktree list 結果>
Issue 情報: <gh issue view または gh issue list の結果>

以下の手順を実行してください。

## 1. 古い Worktree の掃除
bash ~/.claude/skills/gh-pr-approve/cleanup-stale-worktrees.sh

## 2. Issue の確定
Issue 番号が指定されている場合はそのまま使用する。
Issue 番号が指定されていない場合は Issue リストを表示してユーザーに番号を入力させる:
  「どの Issue で作業を開始しますか？番号を入力してください:」

## 3. ブランチ名を生成する
Issue のラベルに基づいてプレフィックスを決定:
- bug/fix/hotfix ラベル → fix/
- それ以外 → feature/

ブランチ名: <プレフィックス>/issue-<Issue番号>-<英語スラッグ>
例: feature/issue-123-add-preview / fix/issue-456-parse-error

## 4. Worktree を作成する
git rev-parse --git-common-dir で init モード（.bare）か判定する。

init モード（.bare 構造）の場合:
  CONTAINER_DIR=$(dirname $(git rev-parse --git-common-dir))
  git worktree add "${CONTAINER_DIR}/<ブランチ種別>" -b <ブランチ名>

通常モードの場合:
  PROJ=$(basename $(git rev-parse --show-toplevel))
  git worktree add "../${PROJ}-<ブランチ種別>" -b <ブランチ名>

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
WORKTREE_ABSPATH=$(cd <Worktree パス> && pwd)
bash ~/.claude/skills/_shared/copy-to-clipboard.sh "cd ${WORKTREE_ABSPATH} && claude"

## 完了報告
以下の形式で報告する:

Issue #<番号> から作業を開始しました。

Issue: <タイトル>
ブランチ: <ブランチ名>
作業ディレクトリ: <Worktree の絶対パス>
Draft PR: #<PR番号>

📋 クリップボードにコピー済み: cd <Worktreeの絶対パス> && claude
新しいターミナルで貼り付けて作業を開始してください。
```
