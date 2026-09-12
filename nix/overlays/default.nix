_: prev: {
  herdr = prev.callPackage ./herdr.nix { };
  zabrze = prev.callPackage ./zabrze.nix { };
}
