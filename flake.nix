{
  description = "yu-sz's dotfiles";

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
        {
          config,
          pkgs,
          lib,
          ...
        }:
        {
          formatter = pkgs.nixfmt-tree;

          pre-commit.check.enable = false;
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
            gitleaks = {
              enable = true;
              name = "gitleaks";
              description = "Detect secrets in git commits";
              entry = "${pkgs.gitleaks}/bin/gitleaks git --pre-commit --staged --verbose";
              language = "system";
              pass_filenames = false;
            };
            markdownlint = {
              enable = true;
              entry = lib.mkForce "${pkgs.markdownlint-cli}/bin/markdownlint -c .markdownlint.yaml";
            };
            prettier = {
              enable = true;
              types_or = [
                "markdown"
                "yaml"
              ];
            };
            selene.enable = true;
            stylua-check = {
              enable = true;
              name = "stylua-check";
              description = "Check Lua formatting with stylua";
              entry = "${pkgs.stylua}/bin/stylua --check";
              language = "system";
              types = [ "lua" ];
            };
          };

          devShells.default = pkgs.mkShell {
            inherit (config.pre-commit) shellHook;
            packages = config.pre-commit.settings.enabledPackages ++ [
              pkgs.just
              pkgs.gitleaks
              pkgs.prettier
              pkgs.stylua
              pkgs.shfmt
              pkgs.selene
            ];
          };
        };

      flake =
        let
          sharedOverlays = [ (import ./nix/overlays) ];

          allowedUnfree = [
            "claude-code"
            "copilot-language-server"
          ];

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
                    pkg: builtins.elem (inputs.nixpkgs.lib.getName pkg) allowedUnfree;
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

          mkHomeConfig =
            {
              username,
              system ? "x86_64-linux",
            }:
            inputs.home-manager.lib.homeManagerConfiguration {
              pkgs = import inputs.nixpkgs {
                inherit system;
                overlays = sharedOverlays;
                config.allowUnfreePredicate = pkg: builtins.elem (inputs.nixpkgs.lib.getName pkg) allowedUnfree;
              };
              modules = [ ./nix/home ];
              extraSpecialArgs = {
                inherit username;
                dotfilesRelPath = "Projects/dotfiles";
              };
            };
        in
        {
          darwinConfigurations = {
            "yu-sz" = mkDarwinConfig { username = "yu-sz"; };
            "yutasuzukinoMacBook-Pro" = mkDarwinConfig { username = "yuta.suzuki"; };
          };

          homeConfigurations = {
            "ci@linux" = mkHomeConfig { username = "ci"; };
          };
        };
    };
}
