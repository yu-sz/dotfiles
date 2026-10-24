# brotli 1.2.0 の CVE-2026-111497（デコーダの境界外書き込み）対応。
# 修正済み brotli 1.2.1 は nixpkgs の staging にあり nixpkgs-unstable 未到達のため、
# 任意のサーバから fetch する git だけ、上流修正をパッチ適用した brotli でリンクした libcurl に差し替える。
# brotli も pkgs.git も上書きしない（依存先が全て再ビルドになるため）。home.packages でこの別名を使う。
# - 上流修正: https://github.com/google/brotli/commit/0ed4268a4401abcb4472096340477cf4af7d1a2b
# - nixpkgs: https://github.com/NixOS/nixpkgs/pull/577208
{
  lib,
  fetchurl,
  brotli,
  curl,
  git,
}:
assert lib.assertMsg (lib.versionOlder brotli.version "1.2.1")
  "Overlay may no longer be needed: brotli >= 1.2.1 reached nixpkgs. Try removing.";
let
  brotliPatched = brotli.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      (fetchurl {
        url = "https://github.com/google/brotli/commit/0ed4268a4401abcb4472096340477cf4af7d1a2b.patch?full_index=1";
        hash = "sha256-1vliUJAAIj3vcGKVgim9CEV+XgMuftDR2U+3kLBUsfw=";
      })
    ];
  });
in
git.override {
  curl = curl.override { brotli = brotliPatched; };
}
