#!/usr/bin/env bash
# リポジトリのコンテキスト情報を一括取得する
# 使用方法: eval "$(bash ~/.claude/skills/_shared/detect-context.sh)"
# 出力: KEY=VALUE 形式（eval で変数として展開可能）

set -euo pipefail

# --- カレントブランチ ---
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")

# --- デフォルトブランチ（1回で取得、失敗時はフォールバック）---
DEFAULT_BRANCH=$(gh api repos/:owner/:repo --jq '.default_branch' 2>/dev/null) \
  || DEFAULT_BRANCH=$(git remote show origin 2>/dev/null | awk '/HEAD branch/{print $NF}') \
  || DEFAULT_BRANCH="main"

# / が含まれていたら feature ブランチと判断して再検証
if echo "$DEFAULT_BRANCH" | grep -q '/'; then
  for candidate in main master; do
    if git rev-parse --verify "origin/$candidate" &>/dev/null 2>&1; then
      DEFAULT_BRANCH="$candidate"
      break
    fi
  done
fi

# --- IS_DEFAULT ---
if [ "$CURRENT_BRANCH" = "$DEFAULT_BRANCH" ]; then
  IS_DEFAULT="true"
else
  IS_DEFAULT="false"
fi

# --- オーナー・リポジトリ名 ---
OWNER_REPO=$(gh repo view --json owner,name --jq '"\(.owner.login)/\(.name)"' 2>/dev/null || echo "/")
OWNER="${OWNER_REPO%%/*}"
REPO="${OWNER_REPO##*/}"

# --- MAIN_REPO / WORKTREE_PATH ---
WORKTREE_PATH="none"
MAIN_REPO=""

WORKTREE_LIST=$(git worktree list --porcelain 2>/dev/null)
WORKTREE_COUNT=$(printf '%s\n' "$WORKTREE_LIST" | grep -c '^worktree ' || true)

if [ "$WORKTREE_COUNT" -le 1 ]; then
  # Worktree なし: 現在のディレクトリが MAIN_REPO
  MAIN_REPO=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
  WORKTREE_PATH="none"
else
  HAS_BARE=$(printf '%s\n' "$WORKTREE_LIST" | grep -c '^bare$' || true)

  if [ "$HAS_BARE" -gt 0 ]; then
    # bare worktree 構造: デフォルトブランチの worktree を MAIN_REPO に
    MAIN_REPO=$(printf '%s\n' "$WORKTREE_LIST" | awk -v branch="refs/heads/$DEFAULT_BRANCH" '
      /^worktree /{wt=$2}
      /^branch / && $2==branch{print wt; exit}
    ')
    CURRENT_TOPLEVEL=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
    if [ "$CURRENT_BRANCH" = "$DEFAULT_BRANCH" ]; then
      WORKTREE_PATH="none"
    else
      WORKTREE_PATH="$CURRENT_TOPLEVEL"
    fi
  else
    # 通常 worktree 構造: 最初のエントリが MAIN_REPO
    MAIN_REPO=$(printf '%s\n' "$WORKTREE_LIST" | awk '/^worktree /{print $2; exit}')
    CURRENT_TOPLEVEL=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
    if [ "$CURRENT_TOPLEVEL" = "$MAIN_REPO" ]; then
      WORKTREE_PATH="none"
    else
      WORKTREE_PATH="$CURRENT_TOPLEVEL"
    fi
  fi
fi

printf 'CURRENT_BRANCH=%s\n' "$CURRENT_BRANCH"
printf 'DEFAULT_BRANCH=%s\n' "$DEFAULT_BRANCH"
printf 'IS_DEFAULT=%s\n' "$IS_DEFAULT"
printf 'OWNER=%s\n' "$OWNER"
printf 'REPO=%s\n' "$REPO"
printf 'MAIN_REPO=%s\n' "$MAIN_REPO"
printf 'WORKTREE_PATH=%s\n' "$WORKTREE_PATH"
