# FIXME(nixpkgs#493910): cli-helpers 2.10.0 のテストが新 Pygments で落ち、pgcli 経由で home-manager build を破壊する。
# bump PR マージ後にこの overlay は削除する (assertion が版差分を自動検知して eval を止める)。
# - Issue: https://github.com/NixOS/nixpkgs/issues/513102
# - Bump:  https://github.com/NixOS/nixpkgs/pull/493910 (2.10.0 -> 2.14.0)
{ lib }:
_: pyprev: {
  cli-helpers =
    assert lib.assertMsg (pyprev.cli-helpers.version == "2.10.0")
      "Overlay nix/overlays/cli-helpers.nix is no longer needed: cli-helpers is now ${pyprev.cli-helpers.version}. Delete this overlay.";
    pyprev.cli-helpers.overridePythonAttrs (old: {
      disabledTests = (old.disabledTests or [ ]) ++ [
        "test_style_output"
        "test_style_output_with_newlines"
        "test_style_output_custom_tokens"
      ];
    });
}
