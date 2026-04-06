default:
    @just --list

# nh darwin switch を実行
switch:
    nh darwin switch .

# flake.lock を更新して switch
update:
    nix flake update
    just switch

# Nix ファイルをフォーマット
fmt:
    nix fmt

# フォーマットチェック（差分があればエラー）
fmt-check:
    nix fmt -- --ci

# フォーマットチェック + statix
lint: fmt-check
    statix check .
    deadnix --no-lambda-pattern-names .

# nix flake check を実行
check:
    nix flake check

# Lua ファイルの lint + フォーマットチェック
lint-lua:
    selene config/nvim/ config/wezterm/
    stylua --check config/nvim/ config/wezterm/

# CI 用チェック（Nix 評価 + lint + dry-run build）
ci:
    nix flake check
    just lint
    just lint-lua
    shellcheck -x -e SC1091 scripts/**/*.sh
    nix build .#darwinConfigurations.yu-sz.system --dry-run

# シェル起動時間のベンチマーク
bench:
    hyperfine --warmup 3 'zsh -i -c exit'

# Nix store のガベージコレクション（直近5世代を保持）
clean:
    nh clean all --keep 5 --nogcroots
