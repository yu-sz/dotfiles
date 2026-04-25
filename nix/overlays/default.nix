final: prev: {
  zabrze = prev.callPackage ./zabrze.nix { };

  # cli-helpers の workaround を全 Python interpreter に適用 (詳細: ./cli-helpers.nix)。
  pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
    (import ./cli-helpers.nix { inherit (prev) lib; })
  ];

  # direnv の workaround (詳細: ./direnv.nix)。
  inherit (import ./direnv.nix { inherit (prev) lib; } final prev) direnv;
}
