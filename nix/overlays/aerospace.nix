# FIXME(nixpkgs): darwin の fixupPhase が公式ビルドの署名を破壊し ad-hoc 再署名される。
# その結果 designated requirement が cdhash 完全一致になり、リビルドのたびに
# macOS のアクセシビリティ権限が失効する。
# - 上流の expression: pkgs/by-name/ae/aerospace/package.nix（dontFixup 未設定）
{
  lib,
  aerospace,
}:
assert lib.assertMsg (
  !(aerospace.dontFixup or false)
) "Overlay may no longer be needed: aerospace sets dontFixup upstream. Try removing.";
aerospace.overrideAttrs (_: {
  dontFixup = true;
})
