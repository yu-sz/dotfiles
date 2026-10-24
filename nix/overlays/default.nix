_: prev: {
  # callPackage は final から解決するため、上書き前の派生を明示的に渡す
  aerospace = prev.callPackage ./aerospace.nix { inherit (prev) aerospace; };
  herdr = prev.callPackage ./herdr.nix { };
  # pkgs.git を上書きすると nix / gh / delta など依存先が全て再ビルドになるため別名で定義し、home.packages 側で参照する
  gitWithPatchedBrotli = import ./git.nix {
    inherit (prev)
      lib
      fetchurl
      git
      curl
      brotli
      ;
  };
  mise = prev.callPackage ./mise.nix { inherit (prev) mise; };
  zabrze = prev.callPackage ./zabrze.nix { };
}
