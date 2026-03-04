---
name: gh-save
description: feature ブランチの途中経過をコミット・プッシュし、Issue タイトル・本文と Draft PR 本文を現在の進捗で更新する。
disable-model-invocation: false
user-invocable: true
allowed-tools:
  - Bash
  - Read
---

# gh-save スキル（途中経過の保存）

feature ブランチでの作業途中に、変更をリモートに保存し Issue・Draft PR の進捗を更新する。
マージは行わない。

---

## Step 0: コンテキスト取得

```bash
eval "$(bash ~/.claude/skills/_shared/detect-context.sh)"
```

以下の変数が設定される:
- `CURRENT_BRANCH`, `DEFAULT_BRANCH`, `IS_DEFAULT`
- `OWNER`, `REPO`

---

## Step 1: 変更状態を確認

```bash
git status --short
git diff
git diff --cached
```

未コミットの変更も未プッシュのコミットもない場合:
「保存する変更がありません。」と表示して**停止する**。

→ Step 2 へ

---

## Step 2: スマートコミット（未コミット変更がある場合のみ）

`git status --short` で未コミットの変更がない場合はスキップして Step 3 へ。

変更ファイルをテーマでグループ化し、グループごとにコミット:

```bash
cd $(git rev-parse --show-toplevel)
git add <ファイル1> <ファイル2> ...
git commit -m "<type>: <日本語説明>"
```

コミットメッセージは Conventional Commits 形式（`feat`/`fix`/`chore`/`docs`/`refactor`/`test`/`style`）。
確認なしで即座に実行する。

→ Step 3 へ

---

## Step 3: プッシュ

```bash
git push -u origin $CURRENT_BRANCH
```

→ Step 4 へ

---

## Step 4: Issue 番号を抽出

`CURRENT_BRANCH` から `issue-(\d+)` パターンで Issue 番号を抽出する。

- 抽出できた場合 → Step 5 へ
- 抽出できない場合 → Step 6（PR 更新）へ直接進む（Issue 更新はスキップ）

---

## Step 5: diff・コミットログを分析して Issue を更新

```bash
git diff origin/$DEFAULT_BRANCH...HEAD
git log origin/$DEFAULT_BRANCH..HEAD --oneline
```

分析結果から:
- **タイトル**: 作業の現在の目的を日本語で簡潔に（完了形ではなく進行形）
  例: `KindleのPDF→OCRパイプラインを実装中`
- **本文**: 以下の3段構成
  ```
  ## 完了済み
  - <完了した変更点を箇条書き>

  ## 作業中
  - <現在進行中の変更点>

  ## 残タスク（推定）
  - <diff から読み取れる未完成箇所>
  ```

```bash
gh issue edit <Issue番号> --repo $OWNER/$REPO \
  --title "<進行形タイトル>" \
  --body "<3段構成の本文>"
```

失敗してもスキップして Step 6 へ進む。

→ Step 6 へ

---

## Step 6: Draft PR の本文を更新（存在する場合のみ）

```bash
gh pr list --head $CURRENT_BRANCH --state open --json number,isDraft | \
  jq -r '.[] | select(.isDraft==true) | .number'
```

Draft PR が存在する場合、Step 5 で生成した進捗サマリを使って本文を更新:

```bash
gh pr edit <PR番号> \
  --body "Closes #<Issue番号>

<Step 5 の3段構成の本文>" > /dev/null
```

- Issue 番号が取れなかった場合は `Closes #N` 行を省略する
- Draft PR が存在しない場合はスキップ
- 失敗してもスキップ

→ Step 7 へ

---

## Step 7: 完了メッセージ

以下の形式で表示する:

```
✅ 途中経過を保存しました。

保存した内容：
- コミット: <コミット数>件（スキップした場合は「未コミット変更なし（スキップ）」）
- プッシュ: origin/<ブランチ名>
- Issue #<N> を更新（Issue 番号が取れなかった場合は「Issue 更新なし（ブランチ名に Issue 番号なし）」）
- Draft PR #<N> を更新（PR がない・Issue なしの場合はスキップ旨を記載）
```
