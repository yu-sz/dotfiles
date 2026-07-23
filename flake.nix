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
    nix-claude-code.url = "github:ryoppippi/nix-claude-code";
    herdr = {
      url = "github:ogulcancelik/herdr/v0.7.5";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nixpkgs は follows しない: unstable(26.11)が x86_64-darwin を落としており、
    # hunk 内部の flake-parts が全 system を評価すると throw するため（hunk 自前の lock を使う）
    hunk.url = "github:modem-dev/hunk/v0.17.3";
  };

  nixConfig = {
    extra-substituters = [ "https://ryoppippi.cachix.org" ];
    extra-trusted-public-keys = [
      "ryoppippi.cachix.org-1:b2LbtWNvJeL/qb1B6TYOMK+apaCps4SCbzlPRfSQIms="
    ];
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
            # prettier / selene は hook 有効化により enabledPackages で供給される。
            # gitleaks / stylua は language = "system" のカスタム hook のため明示追加が必要
            packages = config.pre-commit.settings.enabledPackages ++ [
              pkgs.just
              pkgs.gitleaks
              pkgs.stylua
            ];
          };
        };

      flake =
        let
          sharedOverlays = [
            inputs.nix-claude-code.overlays.default
            (import ./nix/overlays)
            inputs.herdr.overlays.default
            # hunk は overlay 未 export のためインライン overlay で pkgs.hunk へ橋渡しする
            (_: prev: {
              hunk = inputs.hunk.packages.${prev.stdenv.hostPlatform.system}.hunk;
            })
          ];

          allowedUnfree = [
            "claude"
            "copilot-language-server"
            "vscode"
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
              modules = [
                ./nix/home
                {
                  home.username = username;
                  home.homeDirectory = "/home/${username}";
                }
              ];
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
