default:
    @just --list

# darwin-rebuild switch を実行
switch:
    sudo darwin-rebuild switch --flake .

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

# Nix store のガベージコレクション
clean:
    nix-collect-garbage -d
