{
  config,
  lib,
  pkgs,
  dotfilesRelPath,
  ...
}:
let
  dotfiles = "${config.home.homeDirectory}/${dotfilesRelPath}";
  mcpLib = import ./mcp-lib.nix { inherit lib; };
  servers = import ./mcp-servers.nix;
  toml = pkgs.formats.toml { };

  mcpGeminiJson = pkgs.writeText "mcp.gemini.json" (builtins.toJSON (mcpLib.toGemini servers));
  mcpCodexToml = toml.generate "mcp.codex.toml" (mcpLib.toCodex servers);

  python = pkgs.python3.withPackages (ps: [ ps.tomli-w ]);

  agentsSync = pkgs.writeShellApplication {
    name = "agents-sync";
    runtimeInputs = [
      pkgs.jq
      python
    ];
    text = ''
      # 使い方: agents-sync [--diff]
      #   tracked base ⊕ Nix 生成 MCP ⊕ untracked local を深マージし、実ファイルとして配置する。
      #   --diff は書き込まず現在のファイルとの差分を表示する（実行時変更の確認用）
      mode="''${1:-sync}"

      existing_sources() {
        for f in "$@"; do
          [ -f "$f" ] && printf '%s\n' "$f"
        done
      }

      # merge_json <keep(dotted,comma)> <existing> <sources...>
      merge_json() {
        local keep="$1" existing="$2"
        shift 2
        jq -n --arg keep "$keep" --slurpfile existing "$existing" -f ${./merge.jq} "$@"
      }

      # emit <format:json|toml> <target> <keep> <base> <sources...>
      emit() {
        local format="$1" target="$2" keep="$3"
        shift 3
        # 第 1 ソース = tracked base は必須。不在は dotfilesRelPath の誤設定なので即エラー
        [ -f "$1" ] || { echo "agents-sync: base not found: $1" >&2; exit 1; }
        local existing tmp
        existing="$(mktemp)"
        tmp="$(mktemp)"
        # target 不在時は existing を空のまま使う。空は JSON（slurpfile → []）/ TOML（{}）双方で
        # 有効な「existing なし」になる。'{}' を書くと TOML として不正でパースが落ちる
        if [ -f "$target" ]; then cat "$target" > "$existing"; fi
        local -a srcs=()
        while IFS= read -r f; do srcs+=("$f"); done < <(existing_sources "$@")
        case "$format" in
          # </dev/null: srcs が空だと jq の inputs が stdin を読みに行きハングする
          json) merge_json "$keep" "$existing" "''${srcs[@]}" < /dev/null > "$tmp" ;;
          toml) python ${./merge-toml.py} "$existing" "$keep" "''${srcs[@]}" > "$tmp" ;;
        esac
        if [ "$mode" = "--diff" ]; then
          echo "== $target"
          diff -u "$target" "$tmp" || true
        else
          mkdir -p "$(dirname "$target")"
          [ -L "$target" ] && rm -f "$target"
          install -m 644 "$tmp" "$target"
        fi
        rm -f "$existing" "$tmp"
      }

      emit json "$HOME/.claude/settings.json" "" \
        "${dotfiles}/config/claude/settings.json" \
        "${dotfiles}/config/claude/settings.local.json"

      emit json "$HOME/.gemini/settings.json" "security.auth,ui.theme" \
        "${dotfiles}/config/gemini/settings.json" \
        "${mcpGeminiJson}" \
        "${dotfiles}/config/gemini/settings.local.json"

      emit toml "$HOME/.codex/config.toml" "projects,notice,tui.model_availability_nux,tui.theme" \
        "${dotfiles}/config/codex/config.toml" \
        "${mcpCodexToml}" \
        "${dotfiles}/config/codex/config.local.toml"
    '';
  };
in
{
  home.packages = [ agentsSync ];

  # linkGeneration の後に固定する。entryAfter [ "writeBoundary" ] だと同順位の実行順が
  # 名前順になり agentsSync が先に走るため、移行 switch で旧 symlink の掃除と競合する
  home.activation.agentsSync = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${agentsSync}/bin/agents-sync
  '';
}
