---
name: gh-finish
description: 作業完了時に一気にマージまで実行する。ブランチ上なら PR 作成→マージ、main 上なら Issue・ブランチ作成から PR マージまで自動判定。
disable-model-invocation: false
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# GitHub 作業完了スキル（完全インライン版）

現在のブランチ状態を判定し、Issue 作成〜マージまでをすべてインラインで実行する。
Skill ツールによるサブスキル委譲は行わない。

## 絶対禁止事項

- `gh pr review --approve` は使用しないこと（自分の PR は GitHub の仕様上承認できない）
- Skill ツールでサブスキルを呼び出さないこと

---

## Step 0: コンテキスト取得

```bash
eval "$(bash ~/.claude/skills/_shared/detect-context.sh)"
```

以下の変数が設定される:
- `CURRENT_BRANCH`, `DEFAULT_BRANCH`, `IS_DEFAULT`
- `OWNER`, `REPO`
- `MAIN_REPO`, `WORKTREE_PATH`

- IS_DEFAULT=true → **フロー A**（Step A-1 へ）
- IS_DEFAULT=false → **フロー B**（Step B-0 へ）

---

## フロー A: main/master 上にいる場合

### Step A-1: 変更内容を収集

```bash
git status --short
git diff
git diff --cached
git log origin/$DEFAULT_BRANCH..HEAD --oneline
```

**変更が一切ない場合**（status・diff・未プッシュコミットすべて空）:
「変更がありません。」と表示して停止する。

→ Step A-2 へ

### Step A-2: Issue タイトルを自動生成

Step A-1 の diff・status・コミットログを分析し、日本語で簡潔な Issue タイトルを生成する。

例: `hooks設定を新フォーマットに修正` / `ダークモード対応を追加`

→ Step A-3 へ

### Step A-3: GitHub Issue を作成

```bash
gh issue create \
  --title "<自動生成タイトル>" \
  --body "<diff に基づいた作業概要>"
```

出力 URL から Issue 番号を記録する。

→ Step A-4 へ

### Step A-4: ブランチを作成

ブランチ名: `issue-<Issue番号>`

**未プッシュコミットがある場合:**
```bash
git checkout -b <ブランチ名>
git branch -f $DEFAULT_BRANCH origin/$DEFAULT_BRANCH
```

**未プッシュコミットがない場合:**
```bash
git checkout -b <ブランチ名>
```

→ Step A-5 へ

### Step A-5: 変更をコミット（スマートコミット）

未コミットの変更がない場合はスキップして Step A-6 へ。

変更ファイルをテーマ（機能追加・修正・設定変更・ドキュメントなど）でグループ化し、グループごとにコミットする:

```bash
git add <ファイル1> <ファイル2> ...
git commit -m "<type>: <日本語説明>"
```

コミットメッセージは Conventional Commits 形式（`feat`/`fix`/`chore`/`docs`/`refactor`/`test`/`style`）。

→ Step A-6 へ

### Step A-6: プッシュして Draft PR を作成

```bash
git push -u origin <ブランチ名>
```

```bash
gh pr create \
  --draft \
  --title "WIP: <Issueタイトル>" \
  --body "Closes #<Issue番号>

作業中..." \
  --head "<ブランチ名>" \
  --base "$DEFAULT_BRANCH"
```

PR 番号を記録する。

→ **Step 1（共通）** へ

---

## フロー B: feature ブランチ上にいる場合

### Step B-0: 変更状態を確認

```bash
git status --short
git log @{u}..HEAD --oneline 2>/dev/null
```

- 未コミットの変更あり → Step B-1 へ
- 未プッシュのコミットあり → `git push` して **Step 1（共通）** へ
- すべて完了済み → **Step 1（共通）** へ

### Step B-1: 変更をコミット（スマートコミット）

```bash
git diff
git diff --cached
```

変更ファイルをテーマでグループ化し、グループごとにコミットする:

```bash
git add <ファイル1> <ファイル2> ...
git commit -m "<type>: <日本語説明>"
```

```bash
git push -u origin $(git branch --show-current)
```

→ **Step 1（共通）** へ

---

## Step 1（共通）: コンテキスト確認

Step 0 の `detect-context.sh` で取得済みの変数（`MAIN_REPO`, `WORKTREE_PATH`）をそのまま使用する。
再取得は不要。

→ Step 3 へ

---

## Step 3（共通）: PR タイトル・本文を生成して確定

### Step 3-1: ブランチ名から Issue 番号を抽出

`CURRENT_BRANCH` の `issue-(\d+)` パターンで抽出する。
見つからない場合は警告を表示して停止する。

→ Step 3-2 へ

### Step 3-2: 未コミット変更の確認

```bash
git status --short
```

変更がある場合は Step A-5 と同様にコミット・プッシュしてから次へ進む。

→ Step 3-3 へ

### Step 3-3: 既存 Draft PR を検索

```bash
gh pr list --head $CURRENT_BRANCH --state open --json number,isDraft,title
```

- Draft PR あり → PR 番号を記録して Step 3-4A へ
- Draft PR なし → Step 3-4B（新規 PR 作成）へ

### Step 3-4A: PR 本文を生成して pr-finalize.sh を実行

ブランチの変更内容を分析し、PR タイトル（WIP プレフィックスなし）と本文を生成する。

```bash
cat > /tmp/pr-body-$PR_NUMBER.md << 'PREOF'
Closes #<Issue番号>

<変更内容の詳細>
PREOF
```

```bash
bash ~/.claude/skills/gh-finish/pr-finalize.sh \
  "$OWNER" "$REPO" "<PR番号>" "<Issue番号>" "<タイトル>" /tmp/pr-body-$PR_NUMBER.md
```

→ Step 4 へ

### Step 3-4B: 新規 PR を作成

```bash
gh pr create \
  --title "<タイトル>" \
  --body "Closes #<Issue番号>

<変更内容の詳細>"
```

PR 番号を記録して → Step 4 へ

---

## Step 4（共通）: PR 承認・マージ・Issue クローズ

Step 3-4A を経由した場合は `pr-finalize.sh` が承認・マージ・Issue クローズまで完了済み。
**Step 3-4B（新規 PR 作成）を経由した場合のみ**以下を実行する:

### Step 4-1: GitHub App Bot で PR 承認

```bash
bash ~/.claude/skills/gh-pr-approve/approve-pr.sh $OWNER $REPO <PR番号>
```

**403 エラーの場合:** ブランチ保護が無効の可能性があるため、承認なしで Step 4-2 へ進む。

→ Step 4-2 へ

### Step 4-2: PR をマージ

```bash
gh pr merge <PR番号> --squash --repo $OWNER/$REPO
```

→ Step 4-3 へ

### Step 4-3: Issue クローズ確認

```bash
gh issue view <Issue番号> --repo $OWNER/$REPO --json state --jq '.state'
```

`CLOSED` でない場合:

```bash
gh issue close <Issue番号> --repo $OWNER/$REPO
```

→ Step 5 へ

---

## Step 5（共通）: 後処理

```bash
bash ~/.claude/skills/gh-pr-approve/cleanup-after-merge.sh \
  "$MAIN_REPO" \
  "$WORKTREE_PATH" \
  "$DEFAULT_BRANCH" \
  "$CURRENT_BRANCH"
```

→ Step 6 へ

---

## Step 6: 完了メッセージ

以下の形式で表示する:

```
✅ PR のマージと後処理が完了しました。

完了した作業：
- Issue #<N> を作成（フロー A の場合のみ）
- ブランチ <ブランチ名> を作成・コミット
- PR #<N> を作成・マージ
- Issue #<N> をクローズ
- <デフォルトブランチ> ブランチに切り替え・最新を取得
- ローカル・リモートブランチを削除
```
