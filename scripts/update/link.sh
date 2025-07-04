#!/usr/bin/env bash

export CUR_DIR="$(
  cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1
  pwd
)"
export REPO_DIR="$(
  cd "${CUR_DIR}/../.." || exit 1
  pwd
)"

## dry-run（何が削除されるか確認）
echo "以下のシンボリックリンクが削除されます:"
find "$XDG_CONFIG_HOME" -maxdepth 1 -type l -exec echo "  {}" \;
echo ""

# ---
## 実行の確認
read -p "本当に上記を削除して、シンボリックリンクを再作成しますか？ (y/n): " confirm
if [[ "$confirm" =~ ^[yY]$ ]]; then
  echo "シンボリックリンクを削除しています..."
  find "$XDG_CONFIG_HOME" -maxdepth 1 -type l -delete
  echo "削除が完了しました。"

  echo "新しいシンボリックリンクを作成しています..."
  ln -sfv "$REPO_DIR/config/"* "$XDG_CONFIG_HOME"
  echo "シンボリックリンクの作成が完了しました。"
else
  echo "操作はキャンセルされました。"
fi
