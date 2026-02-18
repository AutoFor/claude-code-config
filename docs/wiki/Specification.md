# 仕様書

Claude Code dotfiles の機能一覧と仕様です。

## スキル一覧

### Git ワークフロー

| スキル | コマンド | 説明 |
|--------|---------|------|
| gh-worktree-branch | `/gh-worktree-branch <説明>` | 新規 Issue 作成 → Worktree + ブランチ作成 → Draft PR |
| gh-worktree-from-issue | `/gh-worktree-from-issue [番号]` | 既存 Issue → Worktree + ブランチ作成 → Draft PR |
| gh-branch | `/gh-branch` | diff から Issue + ブランチ作成（Worktree なし） |
| gh-pr-create | `/gh-pr-create` | Draft PR を Ready for Review に変更し、承認・マージまで実行 |
| gh-pr-approve | `/gh-pr-approve` | Bot で PR 承認 → マージ → Issue クローズ → Worktree 削除 |
| gh-finish | `/gh-finish` | 状況を自動判定し、Issue 作成〜マージまで一括実行 |

### コーディング

| スキル | コマンド | 説明 |
|--------|---------|------|
| japanese-comments | `/japanese-comments` | TypeScript/JS コードに日本語の行末コメントを追加 |
| smart-commit | `/smart-commit` | 変更をテーマ別に分割し Conventional Commits 形式でコミット |

### ユーティリティ

| スキル | コマンド | 説明 |
|--------|---------|------|
| z-cheatsheet | `/z-cheatsheet` | dotfiles のショートカット・コマンド検索 |
| z-cheatsheet-add | `/z-cheatsheet-add` | チートシートに項目を追加 |
| gh-wiki-update | `/gh-wiki-update` | コード変更から Wiki ドキュメントを自動更新 |

## ワークフロー

### 作業開始から完了まで

```
/gh-worktree-branch "機能追加"
    │
    ├── Issue 作成
    ├── Worktree + ブランチ作成
    └── Draft PR 作成
        │
        ▼
    コーディング作業
        │
        ▼
/gh-finish
    │
    ├── /smart-commit（変更をコミット）
    ├── /gh-wiki-update（Wiki 更新）
    ├── /gh-pr-create（PR 作成）
    └── /gh-pr-approve（承認・マージ）
        │
        ▼
    GitHub Actions: docs/wiki/ → Wiki 同期
```

### Wiki 更新の仕組み

- `/docs/wiki/` 配下の Markdown ファイルがドキュメントの正（ソース）
- コード変更時に `/gh-wiki-update` スキルが `/docs/wiki/` を更新
- main ブランチにマージされると GitHub Actions が Wiki リポジトリに自動同期

## 通知

| イベント | 通知内容 | サウンド |
|---------|---------|---------|
| Stop（応答完了） | 処理が完了しました | Reminder |
| Notification（入力待ち） | 許可または入力を待っています | IM |

---

*最終更新: 2026-02-18*
