_: prev: {
  # callPackage は final から解決するため、上書き前の派生を明示的に渡す
  aerospace = prev.callPackage ./aerospace.nix { inherit (prev) aerospace; };
  herdr = prev.callPackage ./herdr.nix { };
  zabrze = prev.callPackage ./zabrze.nix { };
}
