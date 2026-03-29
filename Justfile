default:
    @just --list

# darwin-rebuild switch を実行
switch:
    darwin-rebuild switch --flake .

# flake.lock を更新して switch
update:
    nix flake update
    just switch

# nixfmt + statix でリントチェック
lint:
    nix fmt -- --check .
    statix check .

# Nix store のガベージコレクション
clean:
    nix-collect-garbage -d
