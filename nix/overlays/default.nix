_final: prev: {
  zabrze = prev.callPackage ./zabrze.nix { };
  sketchybar-app-font = prev.callPackage ./sketchybar-app-font.nix { };
}
