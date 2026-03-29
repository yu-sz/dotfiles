if command -v nix &>/dev/null; then
  alias nd="nix develop"
  alias ndc="nix develop --command"
  alias nf="nix flake"
  alias nfu="nix flake update"
  alias ngc="nix-collect-garbage -d"

  if [[ "$OSTYPE" == darwin* ]]; then
    alias drs='sudo darwin-rebuild switch --flake ~/Projects/dotfiles'
  fi
fi
