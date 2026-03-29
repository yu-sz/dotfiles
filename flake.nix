{
  description = "suta-ro's dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs =
    {
      nixpkgs,
      nix-darwin,
      home-manager,
      nix-homebrew,
      ...
    }:
    let
      sharedOverlays = [
        # TODO: nixpkgs-unstable に direnv 修正 (PR #502769) が到達したら削除
        (_final: prev: {
          direnv = prev.direnv.overrideAttrs (old: {
            postPatch = (old.postPatch or "") + ''
              substituteInPlace GNUmakefile --replace-fail " -linkmode=external" ""
            '';
          });
        })
        (import ./nix/overlays)
      ];

      supportedSystems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];
      forEachSystem = nixpkgs.lib.genAttrs supportedSystems;

      mkDarwinConfig =
        {
          username,
          system ? "aarch64-darwin",
        }:
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = { inherit username; };
          modules = [
            {
              nixpkgs.overlays = sharedOverlays;
              nixpkgs.config.allowUnfreePredicate =
                pkg:
                builtins.elem (nixpkgs.lib.getName pkg) [
                  "claude-code"
                ];
            }
            ./nix/hosts/darwin-shared.nix
            nix-homebrew.darwinModules.nix-homebrew
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.${username} = import ./nix/home;
                extraSpecialArgs = { inherit username; };
              };
            }
          ];
        };
    in
    {
      darwinConfigurations = {
        "yutanoMacBook-Pro" = mkDarwinConfig { username = "suta-ro"; };
      };

      devShells = forEachSystem (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = sharedOverlays;
          };
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              nixfmt
              statix
              deadnix
              just
            ];
          };
        }
      );

      formatter = forEachSystem (system: nixpkgs.legacyPackages.${system}.nixfmt);

      # Linux (standalone home-manager) — 将来用
      # homeConfigurations."<user>@ubuntu" = home-manager.lib.homeManagerConfiguration {
      #   pkgs = import nixpkgs { system = "x86_64-linux"; overlays = sharedOverlays; };
      #   modules = [ ./nix/home ];
      #   extraSpecialArgs = { username = "<user>"; };
      # };
    };
}
