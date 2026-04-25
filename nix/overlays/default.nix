_final: prev: {
  zabrze = prev.callPackage ./zabrze.nix { };

  # cli-helpers の workaround を全 Python interpreter に適用 (詳細: ./cli-helpers.nix)。
  pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
    (import ./cli-helpers.nix { inherit (prev) lib; })
  ];
}
