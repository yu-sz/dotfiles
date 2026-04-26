final: prev: {
  zabrze = prev.callPackage ./zabrze.nix { };
  sketchybar-app-font = prev.callPackage ./sketchybar-app-font.nix { };

  # direnv の workaround (詳細: ./direnv.nix)。
  inherit (import ./direnv.nix { inherit (prev) lib; } final prev) direnv;
}
