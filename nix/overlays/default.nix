final: prev:
{
  herdr = prev.callPackage ./herdr.nix { };
  zabrze = prev.callPackage ./zabrze.nix { };
}
// import ./sqlfmt.nix { inherit (prev) lib; } final prev
