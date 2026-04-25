# FIXME(nixpkgs#513019): aarch64-darwin で cache.nixos.org が壊れた code signature の fish/zsh を配信中 (NixOS/nix#15638)。
# direnv の checkPhase が `fish ./test/direnv-test.fish` で SIGKILL → ハング。doCheck を無効化する。
# Linux も無効化対象に含むが checkPhase は通常 cache HIT で skip され、shell 連携テストの検知は dotfiles 側では活用できないため許容。
# upstream PR #513081 マージ後に削除する (assertion が変化を自動検知して eval を止める)。
# - Issue: https://github.com/NixOS/nixpkgs/issues/513019
# - Fix:   https://github.com/NixOS/nixpkgs/pull/513081
# - Root:  https://github.com/NixOS/nix/pull/15638
{ lib }:
_: prev: {
  direnv =
    assert lib.assertMsg (prev.direnv.version == "2.37.1" && (prev.direnv.doCheck or true))
      "Overlay nix/overlays/direnv.nix may no longer be needed: direnv=${prev.direnv.version}, doCheck=${
        lib.boolToString (prev.direnv.doCheck or true)
      }. Try removing the overlay.";
    prev.direnv.overrideAttrs (_: {
      doCheck = false;
    });
}
