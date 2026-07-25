final: prev:
{
  zabrze = prev.callPackage ./zabrze.nix { };
}
// import ./sqlfmt.nix { inherit (prev) lib; } final prev
