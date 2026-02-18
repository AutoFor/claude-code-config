---
name: gh-wiki-update
description: コード変更を分析して /docs/wiki/ 配下の Wiki ドキュメント（Markdown）を自動更新する。gh-finish から自動で呼ばれるほか、単独でも使用可能。
disable-model-invocation: false
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - Grep
  - Skill
---

# Wiki ドキュメント更新スキル

コード変更を分析し、`/docs/wiki/` 配下の Markdown ファイルを自動更新する。

## 絶対禁止事項

- Wiki リポジトリ（`.wiki.git`）に直接 push しないこと（GitHub Actions が同期する）
- `/docs/wiki/` 以外のファイルを変更しないこと
- サブスキル（`/smart-commit`）の処理を自分で再実装しないこと

## 実行手順

### ステップ 1: リポジトリ情報取得

```bash
git remote -v
```

owner/repo を特定する。

### ステップ 2: 変更内容の分析

デフォルトブランチを取得:

```bash
git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'
```

デフォルトブランチとの diff を取得:

```bash
git diff origin/<default-branch>...HEAD --name-only
```

```bash
git diff origin/<default-branch>...HEAD
```

変更されたファイルの一覧と内容を把握する。

### ステップ 3: `/docs/wiki/` の現状確認

`/docs/wiki/` が存在するか確認する。

- **存在しない場合**: Skill ツールで `/gh-wiki-init` を呼び出して初期セットアップを実行。完了後、ステップ 4 へ続行する
- **存在する場合**: 既存ページを Read で読み込む

### ステップ 4: ソースコード分析

- 変更されたファイルの内容を読み込む
- プロジェクト全体の構造を把握（README.md、主要設定ファイル等）

### ステップ 5: 更新が必要なページを判定

- 変更ファイルに基づいて、影響を受ける Wiki ページを特定
- 新しいコンポーネント/モジュールが追加された場合 → 詳細設計ページの新規作成を検討

### ステップ 6: Wiki ページ生成・更新

Write ツールで `/docs/wiki/` 内の Markdown ファイルを更新する。

- `_Sidebar.md` を自動再生成（全ページへのリンク一覧）
- 各ページ末尾に最終更新日を記載

### ステップ 7: 変更をコミット

```bash
git status --short docs/wiki/
```

- **変更がある場合** → Skill ツールで `/smart-commit` を呼び出してコミット
- **変更がない場合** → スキップ

### ステップ 8: 完了メッセージ表示

更新したページの一覧を表示する。

---

## Wiki ページ構成（自動判定）

プロジェクトを分析して最適なページ構成を自動判定する。基本構成:

| ページ | 対象読者 | 内容 | 生成ソース |
|--------|---------|------|-----------|
| `Home.md` | 全員（非エンジニア含む） | 概要、目的、導入手順のサマリ | README.md, 設定ファイル |
| `Specification.md` | 全員 | 仕様書: 機能一覧、全体像 | ソースコード全体 |
| 詳細設計ページ（動的） | エンジニア | 各コンポーネントの実装詳細 | 主要モジュールのソース |
| `_Sidebar.md` | 全員 | ナビゲーション | 自動生成（全ページのリンク） |

## 各ページの書き方ルール

- **Home.md**: 平易な日本語、専門用語は避けるか注釈付き、非エンジニアが読んで理解できる
- **Specification.md**: 仕様ベース、「何ができるか」を中心に記述、フローチャートやテーブルを活用
- **詳細設計ページ**: 実装詳細、コード例、呼び出しフロー図、引数・戻り値の仕様
