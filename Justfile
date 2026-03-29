default:
    @just --list

# darwin-rebuild switch を実行
switch:
    darwin-rebuild switch --flake .

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

# Nix store のガベージコレクション
clean:
    nix-collect-garbage -d
