---
name: gh-finish
description: 作業完了時に一気にマージまで実行する。Codex MCP へ委譲。
disable-model-invocation: false
user-invocable: true
allowed-tools:
  - Bash
  - mcp__codex__codex
---

# GitHub 作業完了スキル（Codex委譲版）

## Step 1: コンテキスト収集（Claude Code が実行）

以下を bash で実行して結果を記録する:

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

以下の手順をすべて実行してください。

## ブランチ判定
- 現在ブランチ = デフォルトブランチ → フロー A
- 現在ブランチ ≠ デフォルトブランチ → フロー B

---

## フロー A: デフォルトブランチ上にいる場合

### A-1. 変更内容を収集する
git status --short
git diff
git diff --cached
git log origin/<デフォルトブランチ>..HEAD --oneline

変更が一切ない場合（status・diff・未プッシュコミットすべて空）は「変更がありません。」と表示して終了。

### A-2. Issue タイトルを自動生成する
diff・status・コミットログを分析し、日本語で簡潔なタイトルを生成する。
例: `hooks設定を新フォーマットに修正` / `ダークモード対応を追加`

### A-3. GitHub Issue を作成する
gh issue create \
  --title "<自動生成タイトル>" \
  --body "<diff に基づいた作業概要>"

出力 URL から Issue 番号を記録する。

### A-4. ブランチを作成する
Issue タイトルを英語スラッグに変換（小文字・ハイフン・3〜5語）。
ブランチ名: issue-<Issue番号>-<英語スラッグ>

未プッシュコミットがある場合:
  git checkout -b <ブランチ名>
  git branch -f <デフォルトブランチ> origin/<デフォルトブランチ>

未プッシュコミットがない場合:
  git checkout -b <ブランチ名>

### A-5. 変更をコミットする
未コミットの変更がない場合はスキップ。

ファイルをテーマ（機能追加・修正・設定変更・ドキュメント）でグループ化し、グループごとにコミット:
  git add <ファイル1> <ファイル2> ...
  git commit -m "<type>: <日本語説明>"

コミットメッセージは Conventional Commits 形式（feat/fix/chore/docs/refactor/test/style）。

### A-6. プッシュして Draft PR を作成する
git push -u origin <ブランチ名>
gh pr create \
  --draft \
  --title "WIP: <Issueタイトル>" \
  --body "Closes #<Issue番号>

作業中..." \
  --head "<ブランチ名>" \
  --base "<デフォルトブランチ>"

→ 共通ステップへ

---

## フロー B: feature ブランチ上にいる場合

### B-1. 変更状態を確認する
git status --short
git log @{u}..HEAD --oneline 2>/dev/null

未コミットの変更あり → B-2 へ
未プッシュのコミットあり → git push して共通ステップへ
すべて完了済み → 共通ステップへ

### B-2. 変更をコミットしてプッシュする
git diff
git diff --cached

ファイルをテーマでグループ化してコミット（Conventional Commits、日本語）:
  git add <ファイル1> ...
  git commit -m "<type>: <日本語説明>"
  git push -u origin $(git branch --show-current)

→ 共通ステップへ

---

## 共通: Wiki ドキュメント更新（失敗しても続行）

### W-1. 変更差分を取得する
git fetch origin <デフォルトブランチ>
git diff origin/<デフォルトブランチ>...HEAD --name-only
git diff origin/<デフォルトブランチ>...HEAD

### W-2. docs/wiki/ の存在確認
存在しない場合はスキップ。
存在する場合は既存の Markdown ファイルを cat で読み込む。

### W-3. Wiki ページを更新する
変更内容を分析し、影響を受けるページを更新する。
ユーザー向け仕様の変化がない場合は最終更新日のみ更新。

変更がある場合:
  git add docs/wiki/
  git commit -m "docs: Wiki を更新"
  git push

---

## 共通: PR を Ready for Review に変更

### P-1. ブランチ名から Issue 番号を抽出する
git branch --show-current

issue-(\d+) パターンで抽出。見つからない場合は警告を表示して停止。

### P-2. 未コミット変更を確認する
git status --short

変更がある場合はコミット・プッシュしてから続行。

### P-3. 既存 Draft PR を確認する
gh pr list --head $(git branch --show-current) --state open --json number,isDraft,title

Draft PR あり → P-4A へ
Draft PR なし → P-4B へ

### P-4A. 既存 Draft PR を更新・Ready for Review に変更する
gh api repos/<owner>/<repo>/pulls/<PR番号> -X PATCH \
  -f title="<WIP プレフィックスを除いたタイトル>" \
  -f body="Closes #<Issue番号>

<変更内容の詳細>"

gh pr ready <PR番号>

### P-4B. 新規 PR を作成する
gh pr create \
  --title "<タイトル>" \
  --body "Closes #<Issue番号>

<変更内容の詳細>"

---

## 共通: PR 承認・マージ

### M-1. GitHub App Bot で PR を承認する
bash ~/.claude/skills/gh-pr-approve/approve-pr.sh <owner> <repo> <PR番号>

403 エラーの場合は承認をスキップして M-2 へ進む。

### M-2. PR をマージする
gh pr merge <PR番号> --squash --repo <owner>/<repo>
gh pr view <PR番号> --repo <owner>/<repo> --json state,mergedAt

### M-3. Issue クローズを確認する
gh issue view <Issue番号> --repo <owner>/<repo> --json state

CLOSED でない場合:
  gh issue close <Issue番号> --repo <owner>/<repo>

---

## 共通: 後処理

bash ~/.claude/skills/gh-pr-approve/cleanup-after-merge.sh \
  <メインリポジトリパス> \
  <WorktreeパスまたはNone> \
  <デフォルトブランチ> \
  <ブランチ名>

---

## 完了報告

以下の形式で報告する:

✅ PR のマージと後処理が完了しました。

完了した作業：
- Issue #<N> を作成（フロー A の場合のみ）
- ブランチ <ブランチ名> を作成・コミット
- PR #<N> を作成・マージ
- Issue #<N> をクローズ
- <デフォルトブランチ> ブランチに切り替え・最新を取得
- ローカル・リモートブランチを削除
```
