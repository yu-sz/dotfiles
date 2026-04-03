if command -v nix &>/dev/null; then
  alias nd="nix develop"
  alias ndc="nix develop --command"
  alias nf="nix flake"
  alias nfu="nix flake update"
  alias ngc="nh clean all --keep 5"

  if [[ "$OSTYPE" == darwin* ]]; then
    # unsetopt GLOBAL_RCS により hm-session-vars.sh が読み込まれず NH_DARWIN_FLAKE が未設定のため、明示的にパスを指定
    alias drs='nh darwin switch ~/Projects/dotfiles'
  fi
fi
