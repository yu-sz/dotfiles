{
  jq,
  python3,
  runCommand,
}:
runCommand "agents-merge-test"
  {
    nativeBuildInputs = [
      jq
      (python3.withPackages (ps: [ ps.tomli-w ]))
    ];
  }
  ''
    cd ${./.}
    # 1. ネスト配列の和集合: base.permissions.allow ⊕ local が順序保持で合併すること
    jq -n --arg keep "" --slurpfile existing empty.json -f ${../merge.jq} base.json local.json \
      | jq -e '.permissions.allow == ["Bash(git:*)", "Read", "Bash(local:*)"]'
    # 2. keep: existing の security.auth が保持され、他のランタイムキーは落ちること
    jq -n --arg keep "security.auth" --slurpfile existing existing.json -f ${../merge.jq} base.json \
      | jq -e '.security.auth.type == "oauth" and (has("feedbackSurveyState") | not)'
    # 3. TOML: projects / notice の carry-over と base 優先（tui.notifications = true）
    python3 ${../merge-toml.py} codex-existing.toml "projects,notice" codex-base.toml codex-local.toml \
      | python3 -c 'import sys,tomllib; d=tomllib.loads(sys.stdin.read()); assert d["projects"] and d["tui"]["notifications"] is True'
    # 4. existing 不在（新マシン）: 空ファイルが JSON / TOML 双方で有効な existing になること
    #    （sync.nix の emit は target 不在時に空の existing を渡す。'{}' は TOML 不正）
    jq -n --arg keep "security.auth" --slurpfile existing empty.json -f ${../merge.jq} base.json > /dev/null
    python3 ${../merge-toml.py} empty.json "projects,notice" codex-base.toml \
      | python3 -c 'import sys,tomllib; tomllib.loads(sys.stdin.read())'
    touch $out
  ''
