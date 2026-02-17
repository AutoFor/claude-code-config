# Claude Code dotfiles

Claude Code のグローバル設定・スキル・MCP 設定をまとめた dotfiles リポジトリ。

## 構成

```
.
├── CLAUDE.md                        # グローバルルール（全プロジェクト共通）
├── settings.json                    # フック設定（応答完了通知など）
├── windows-notify.ps1               # Windows トースト通知スクリプト
├── github-app-config.env.example    # GitHub App 認証情報のテンプレート
├── mcp/
│   └── mcp-config.json.example      # MCP サーバー設定のテンプレート
└── skills/
    ├── _shared/
    │   └── copy-to-clipboard.sh     # クロスプラットフォーム クリップボードユーティリティ
    ├── gh-branch/                   # diff から Issue + ブランチ作成（Worktree なし）
    ├── gh-worktree-branch/          # 新規 Issue + Worktree + ブランチ作成
    ├── gh-worktree-from-issue/      # 既存 Issue から Worktree + ブランチ作成
    ├── gh-pr-create/                # PR 作成（Draft PR → Ready for Review）
    ├── gh-pr-approve/               # PR 承認・マージ・後処理
    ├── gh-finish/                   # ブランチ作成〜マージまで一括実行
    ├── japanese-comments/           # TypeScript/JS に日本語コメント追加
    └── smart-commit/                # テーマ別に自動分割コミット
```

## セットアップ

### 1. シンボリックリンク作成

```bash
ln -sf $(pwd)/CLAUDE.md ~/.claude/CLAUDE.md
ln -sf $(pwd)/settings.json ~/.claude/settings.json
ln -sf $(pwd)/windows-notify.ps1 ~/.claude/windows-notify.ps1
ln -sf $(pwd)/skills ~/.claude/skills
```

### 2. MCP サーバー設定

```bash
cp mcp/mcp-config.json.example ~/.claude/mcp.json
# ~/.claude/mcp.json を編集して GitHub PAT を設定
```

### 3. GitHub App 設定（PR 自動承認用）

```bash
cp github-app-config.env.example ~/.config/claude-github-app.env
# 環境変数ファイルを編集して認証情報を設定
```

GitHub App は PR の自動承認に使用します（セルフマージの制限回避）。

## スキル一覧

### Git ワークフロー

| スキル | コマンド | 説明 |
|--------|---------|------|
| gh-worktree-branch | `/gh-worktree-branch <説明>` | 新規 Issue 作成 → Worktree + ブランチ作成 → Draft PR |
| gh-worktree-from-issue | `/gh-worktree-from-issue [番号]` | 既存 Issue → Worktree + ブランチ作成 → Draft PR |
| gh-branch | `/gh-branch` | diff から Issue + ブランチ作成（Worktree なし） |
| gh-pr-create | `/gh-pr-create` | Draft PR を Ready for Review に変更し、承認・マージまで実行 |
| gh-pr-approve | `/gh-pr-approve` | PR 承認 → マージ → Issue クローズ → Worktree 削除 |
| gh-finish | `/gh-finish` | 状況を自動判定し、ブランチ作成〜マージまで一括実行 |

### コーディング

| スキル | コマンド | 説明 |
|--------|---------|------|
| japanese-comments | `/japanese-comments` | TypeScript/JS コードに日本語の行末コメントを追加 |
| smart-commit | `/smart-commit` | 変更をテーマ別に分割し Conventional Commits 形式でコミット |

## 通知

`settings.json` のフック設定により、Claude Code の応答完了時に Windows トースト通知が表示されます（WSL2 環境、[BurntToast](https://github.com/Windos/BurntToast) モジュールが必要）。

## ワークフロー例

```
# 1. 新しい作業を開始
/gh-worktree-branch ダークモード追加

# 2. コーディング（日本語コメント付き）
「ダークモードのトグルボタンを実装して」

# 3. 作業完了 → PR 作成 → マージまで一括実行
/gh-pr-create
```
