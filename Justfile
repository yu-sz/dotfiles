default:
    @just --list

# OS判定で switch-darwin / switch-linux を呼び分け
switch:
    just switch-{{ if os() == "macos" { "darwin" } else { "linux" } }}

# nh darwin switch を実行
switch-darwin:
    nh darwin switch .

# apt-sync + nh home switch を実行
switch-linux:
    ./scripts/apt-sync.sh
    nh home switch .

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
    selene config/ nix/
    stylua --check config/ nix/

# シェルスクリプトの静的解析（sh では `**` が `*` 扱いのため find で列挙）
lint-sh:
    find scripts -name '*.sh' -exec shellcheck -x -e SC1091 {} +

# Markdown / YAML の lint + フォーマットチェック（Git 追跡ファイルのみ）
lint-docs:
    git ls-files '*.md' | xargs markdownlint -c .markdownlint.yaml
    git ls-files '*.md' '*.yaml' '*.yml' | xargs prettier --check

# CI 用チェック（Nix 評価 + lint + dry-run build）
ci: check lint lint-sh lint-docs
    just ci-{{ if os() == "macos" { "darwin" } else { "linux" } }}

# Darwin 用 dry-run build
ci-darwin:
    nix build .#darwinConfigurations.yu-sz.system --dry-run

# Linux 用 dry-run build
ci-linux:
    nix build .#homeConfigurations.ci@linux.activationPackage --dry-run

# シェル起動時間のベンチマーク
bench:
    hyperfine --warmup 3 'zsh -i -c exit'

# Nix store のガベージコレクション（直近5世代を保持）
clean:
    nh clean all --keep 5 --nogcroots
