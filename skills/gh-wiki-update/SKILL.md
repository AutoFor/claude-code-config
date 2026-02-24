---
name: gh-wiki-update
description: コード変更を分析して /docs/wiki/ 配下の Wiki ドキュメント（Markdown）を自動更新する。Codex MCP へ委譲。
disable-model-invocation: false
user-invocable: true
allowed-tools:
  - Bash
  - mcp__codex__codex
---

# Wiki ドキュメント更新スキル（Codex委譲版）

## Step 1: コンテキスト収集（Claude Code が実行）

```bash
pwd
git branch --show-current
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
git remote get-url origin
ls docs/wiki/ 2>/dev/null || echo "docs/wiki/ not found"
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
docs/wiki/ の状態: <ls 結果>

以下の手順を実行してください。

## 1. 変更内容の分析
git fetch origin <デフォルトブランチ>
git log origin/<デフォルトブランチ>..HEAD --oneline
git diff origin/<デフォルトブランチ>...HEAD --name-only
git diff origin/<デフォルトブランチ>...HEAD

## 2. docs/wiki/ の確認
docs/wiki/ が存在しない場合は「Wiki ディレクトリが見つかりません。/gh-init-wiki を実行してください。」と表示して終了。

存在する場合は既存ページを cat で読み込む:
find docs/wiki -name "*.md" | while read f; do echo "=== $f ==="; cat "$f"; done

## 3. 変更内容に応じて Wiki ページを更新する
- 変更されたファイルの影響を受けるページを特定する
- python3 または tee を使ってファイルを更新する
  例: python3 -c "
content = '''# ページ内容
...
'''
open('docs/wiki/Specification.md', 'w').write(content)
"
- ユーザー向け仕様の変化がない場合は最終更新日のみ更新する
- _Sidebar.md を全ページリンクで再生成する

## 4. ダイアグラムの確認と更新
ls docs/wiki/images/*.drawio 2>/dev/null

既存 .drawio ファイルがある場合は cat で読み込み、変更に応じて XML を更新する。
新規ダイアグラムが必要な場合は docs/wiki/images/<name>.drawio を python3 で作成する。

ダイアグラムを更新・作成した場合は SVG エクスポートする:
xvfb-run drawio --export --format svg --embed-svg-fonts true \
  --output docs/wiki/images/<name>.svg docs/wiki/images/<name>.drawio

## 5. 変更をコミット・プッシュする
git status --short docs/wiki/
変更がある場合:
  git add docs/wiki/
  git commit -m "docs: Wiki を更新"
  git push

変更がない場合はスキップ。

## 完了報告
更新したページの一覧を表示する。

注意: Wiki リポジトリ（.wiki.git）に直接 push しないこと。GitHub Actions が同期する。
```
