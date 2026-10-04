{
  symlinkJoin,
  makeWrapper,
  codex,
}:
# codex 0.157.0 以降は起動時に app-server daemon を立ち上げ、その際 exe の親ディレクトリを
# パッケージルートとみなして codex-package.json を探す。llm-agents.nix（nixpkgs も同様）は
# cargo の成果物を bin/ に置くだけで upstream のパッケージ構造を作らないため、
# `this CLI has no complete local package` で起動できない。
# upstream 修正まで公式の回避策 --no-daemon を既定にする。
# https://github.com/numtide/llm-agents.nix/issues/9887
symlinkJoin {
  name = "codex-${codex.version}";
  paths = [ codex ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/codex --add-flags --no-daemon
  '';
  inherit (codex) meta;
}
