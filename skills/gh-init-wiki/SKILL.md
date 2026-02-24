---
name: gh-init-wiki
description: プロジェクトに docs/wiki/ と GitHub Actions ワークフローを作成し、Wiki 自動同期の土台をセットアップする。Codex MCP へ委譲。
disable-model-invocation: false
user-invocable: true
allowed-tools:
  - Bash
  - mcp__codex__codex
---

# Wiki 初期化スキル（Codex委譲版）

## Step 1: コンテキスト収集（Claude Code が実行）

```bash
pwd
git remote get-url origin
ls docs/wiki/ 2>/dev/null && echo "EXISTS" || echo "NOT_FOUND"
ls README.md package.json Cargo.toml go.mod pyproject.toml 2>/dev/null
find src -maxdepth 2 -type f 2>/dev/null | head -20
```

## Step 2: Codex へ委譲

Step 1 の結果を埋め込んで `mcp__codex__codex` を呼び出す。

`message` に以下を渡す（`<>` 内は Step 1 の実際の値で置換）:

---

```
作業ディレクトリ: <pwd>
リポジトリ (owner/repo): <git remote get-url origin から抽出>
docs/wiki/ の状態: <EXISTS または NOT_FOUND>
プロジェクトファイル: <ls 結果>
ソースファイル構造: <find 結果>

以下の手順を実行してください。

## 1. 既存チェック
docs/wiki/ が EXISTS の場合は「既にセットアップ済みです。/gh-wiki-update で更新できます。」と表示して終了。

## 2. プロジェクト分析
README.md と主要設定ファイルを cat で読み込む。
主要ソースファイルを確認する。

## 3. docs/wiki/ を作成する
mkdir -p docs/wiki/images

プロジェクト分析に基づき以下のファイルを python3 で作成する:

### Home.md
- 平易な日本語
- 非エンジニアが読んで理解できる内容
- プロジェクト概要・目的・できること・使い方

### Specification.md
- 仕様書形式
- 機能一覧（テーブル）・フロー・全体像

### _Sidebar.md
- 全ページへのリンク一覧

## 4. ダイアグラムを作成する
プロジェクトに応じたアーキテクチャ図を docs/wiki/images/architecture.drawio として作成する:

python3 -c "
content = '''<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<mxfile>
  <diagram name=\"Architecture\">
    <mxGraphModel>
      <root>
        <mxCell id=\"0\"/>
        <mxCell id=\"1\" parent=\"0\"/>
        <!-- プロジェクト構成に応じたノードとエッジ -->
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>'''
open('docs/wiki/images/architecture.drawio', 'w').write(content)
"

SVG エクスポート:
xvfb-run drawio --export --format svg --embed-svg-fonts true \
  --output docs/wiki/images/architecture.svg docs/wiki/images/architecture.drawio

## 5. .github/workflows/wiki-sync.yml を作成する
.github/workflows/wiki-sync.yml が存在しない場合のみ:

mkdir -p .github/workflows
python3 -c "
content = '''name: Sync Wiki

on:
  push:
    branches: [main]
    paths:
      - \"docs/wiki/**\"

permissions:
  contents: write

jobs:
  sync-wiki:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: Andrew-Chen-Wang/github-wiki-action@v4
        with:
          path: \"docs/wiki/\"
          strategy: clone
'''
open('.github/workflows/wiki-sync.yml', 'w').write(content)
"

## 6. コミット・プッシュする
git add docs/wiki/ .github/workflows/wiki-sync.yml
git commit -m "docs: Wiki 初期セットアップ"
git push

## 完了報告
生成したファイルの一覧を表示する。
あわせて以下の注意を表示:
「初回は GitHub リポジトリの Wiki タブで初期ページを手動作成する必要があります（その後は GitHub Actions が自動同期します）。」
```
