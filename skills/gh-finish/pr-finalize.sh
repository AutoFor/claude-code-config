#!/usr/bin/env bash
# PR の更新・ready変換・承認・マージ・Issue クローズを一括実行
# 使用方法: pr-finalize.sh <owner> <repo> <pr_number> <issue_number> <title> <body_file>
# body_file: PR 本文を含むファイルパス（- で stdin から読む）

set -euo pipefail

if [ $# -ne 6 ]; then
  echo "Usage: $0 <owner> <repo> <pr_number> <issue_number> <title> <body_file>" >&2
  exit 1
fi

OWNER="$1"
REPO="$2"
PR_NUMBER="$3"
ISSUE_NUMBER="$4"
TITLE="$5"
BODY_FILE="$6"

APPROVE_SCRIPT="$(cd "$(dirname "$0")" && pwd)/../gh-pr-approve/approve-pr.sh"

# Step 1: PR タイトル・本文を更新（出力抑制）
gh api "repos/$OWNER/$REPO/pulls/$PR_NUMBER" -X PATCH \
  -f "title=$TITLE" \
  -F "body=@$BODY_FILE" \
  > /dev/null
echo "PR #$PR_NUMBER updated."

# Step 2: Draft → Ready for Review
gh pr ready "$PR_NUMBER" --repo "$OWNER/$REPO"
echo "PR #$PR_NUMBER is now ready for review."

# Step 3: 承認（失敗時は警告のみ・処理続行）
if [ -f "$APPROVE_SCRIPT" ]; then
  bash "$APPROVE_SCRIPT" "$OWNER" "$REPO" "$PR_NUMBER" || {
    echo "WARNING: Approval failed (branch protection may be disabled). Continuing..." >&2
  }
fi

# Step 4: マージ
gh pr merge "$PR_NUMBER" --squash --repo "$OWNER/$REPO"
echo "PR #$PR_NUMBER merged."

# Step 5: Issue クローズ確認
ISSUE_STATE=$(gh issue view "$ISSUE_NUMBER" --repo "$OWNER/$REPO" --json state --jq '.state' 2>/dev/null || echo "")
if [ "$ISSUE_STATE" != "CLOSED" ]; then
  gh issue close "$ISSUE_NUMBER" --repo "$OWNER/$REPO"
  echo "Issue #$ISSUE_NUMBER closed."
else
  echo "Issue #$ISSUE_NUMBER already closed."
fi
