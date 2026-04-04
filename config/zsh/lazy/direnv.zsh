# home-manager の enableZshIntegration=false のため手動で hook を登録 (zsh-defer で遅延ロード)
if command -v direnv &>/dev/null; then
  eval "$(direnv hook zsh)"
fi
