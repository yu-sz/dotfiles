# FIXME(nixpkgs): pythonMetadataCheckPhase が pname "sqlfmt" で dist-info を引くが、
# 実際の配布名は shandy-sqlfmt のため PackageNotFoundError でビルドが失敗する
# - Issue: 未報告 (2026-07-25 時点。tracking nixpkgs#475732 にも記載なし)
# - Hydra: https://hydra.nixos.org/build/338805942 (2026-07-21 から失敗)
{ lib }:
_: prev: {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (_: pyprev: {
      sqlfmt =
        assert lib.assertMsg (
          pyprev.sqlfmt.version == "0.30.0" && !(pyprev.sqlfmt ? dontCheckPythonMetadata)
        ) "Overlay may no longer be needed: sqlfmt=${pyprev.sqlfmt.version}. Try removing.";
        pyprev.sqlfmt.overridePythonAttrs (_: {
          dontCheckPythonMetadata = true;
        });
    })
  ];
}
