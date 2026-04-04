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
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.git-hooks.flakeModule ];

      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      perSystem =
        { config, pkgs, ... }:
        {
          formatter = pkgs.nixfmt-tree;

          pre-commit.settings.hooks = {
            nixfmt.enable = true;
            statix.enable = true;
            deadnix.enable = true;
            shellcheck = {
              enable = true;
              types_or = [
                "sh"
                "bash"
              ];
              excludes = [ "^\\.envrc$" ];
              args = [
                "-x"
                "-e"
                "SC1091"
              ];
            };
          };

          devShells.default = pkgs.mkShell {
            inherit (config.pre-commit) shellHook;
            packages = config.pre-commit.settings.enabledPackages ++ [ pkgs.just ];
          };
        };

      flake =
        let
          sharedOverlays = [ (import ./nix/overlays) ];

          mkDarwinConfig =
            {
              username,
              system ? "aarch64-darwin",
            }:
            inputs.nix-darwin.lib.darwinSystem {
              inherit system;
              specialArgs = { inherit username; };
              modules = [
                {
                  nixpkgs.overlays = sharedOverlays;
                  nixpkgs.config.allowUnfreePredicate =
                    pkg: builtins.elem (inputs.nixpkgs.lib.getName pkg) [ "claude-code" ];
                }
                ./nix/hosts/darwin-shared.nix
                inputs.nix-homebrew.darwinModules.nix-homebrew
                inputs.home-manager.darwinModules.home-manager
                {
                  home-manager = {
                    useGlobalPkgs = true;
                    useUserPackages = true;
                    backupFileExtension = "hm-backup";
                    users.${username} = import ./nix/home;
                    extraSpecialArgs = {
                      inherit username;
                      dotfilesRelPath = "Projects/dotfiles";
                    };
                  };
                }
              ];
            };
        in
        {
          darwinConfigurations = {
            "yutanoMacBook-Pro" = mkDarwinConfig { username = "suta-ro"; };
          };

          # Linux (standalone home-manager) — 将来用
          # homeConfigurations."<user>@ubuntu" = home-manager.lib.homeManagerConfiguration {
          #   pkgs = import inputs.nixpkgs { system = "x86_64-linux"; overlays = sharedOverlays; };
          #   modules = [ ./nix/home ];
          #   extraSpecialArgs = { username = "<user>"; };
          # };
        };
    };
}
