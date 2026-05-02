final: prev: {
  zabrze = prev.callPackage ./zabrze.nix { };

  # direnv の workaround (詳細: ./direnv.nix)。
  inherit (import ./direnv.nix { inherit (prev) lib; } final prev) direnv;
}
