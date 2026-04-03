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

# Nix store のガベージコレクション（直近5世代を保持）
clean:
    nh clean all --keep 5 --nogcroots
