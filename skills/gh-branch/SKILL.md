---
name: gh-branch
description: 作業中の変更内容（diff）から自動で GitHub Issue を作成し、ブランチを作成する（Worktree なし）。Codex MCP へ委譲。
disable-model-invocation: false
user-invocable: true
allowed-tools:
  - Bash
  - mcp__codex__codex
---

# Git ブランチ作成スキル（Codex委譲版）

引数は一切使用しない（渡されても無視する）。
常に現在の変更内容から Issue タイトルを自動生成する。

## Step 1: コンテキスト収集（Claude Code が実行）

```bash
pwd
git branch --show-current
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
git remote get-url origin
git status --short
git diff --stat
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
変更ファイル: <git status --short>
変更差分: <git diff --stat>

以下の手順を実行してください。

## 変更確認
git status --short
git diff
git diff --cached
git log origin/<デフォルトブランチ>..HEAD --oneline

変更が何もない場合（status が空、diff が空、未プッシュコミットもなし）は
「変更がありません。先にコードを変更してから実行してください。」と表示して終了。

## Issue タイトルを自動生成する
diff・status・コミットログを分析し、日本語で簡潔な Issue タイトルを生成する。
例: `hooks設定を新フォーマットに修正` / `ダークモード対応を追加`

## GitHub Issue を作成する
gh issue create \
  --title "<自動生成タイトル>" \
  --body "<diff に基づいた作業概要>"

出力 URL から Issue 番号を記録する。

## ブランチ名を生成する
Issue タイトルを英語スラッグに変換（小文字・ハイフン・3〜5語）。
ブランチ名: issue-<Issue番号>-<英語スラッグ>
例: issue-17-fix-hooks-config-format

## ブランチを作成する

### デフォルトブランチ上にいて未プッシュコミットがある場合:
git log origin/<デフォルトブランチ>..HEAD --oneline
コミットがある場合:
  git checkout -b <ブランチ名>
  git branch -f <デフォルトブランチ> origin/<デフォルトブランチ>

### それ以外（デフォルトブランチ上でコミットなし、または別ブランチ）:
  git checkout -b <ブランチ名>

## 変更をコミットする
git status --short で未コミット変更を確認。
変更がなければスキップ。

変更がある場合、ファイルをテーマでグループ化してコミット（Conventional Commits 形式、日本語）:
  git add <ファイル1> <ファイル2> ...
  git commit -m "<type>: <日本語説明>"

## プッシュして Draft PR を作成する
git push -u origin <ブランチ名>
gh pr create \
  --draft \
  --title "WIP: <Issueタイトル>" \
  --body "Closes #<Issue番号>

作業中..." \
  --head "<ブランチ名>" \
  --base "<デフォルトブランチ>"

## 完了報告
以下の形式で報告する（これ以上何も出力しない）:

処理が終了しました。

Issue: #<Issue番号> - <Issueタイトル>
ブランチ: <ブランチ名>
Draft PR: #<PR番号>

（デフォルトブランチから未プッシュコミットを移植した場合はその旨も記載）
```
