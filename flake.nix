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
    # nixpkgs は follows しない: codex は Rust ソースビルドで、follows すると
    # cache.numtide.com のヒットが nixpkgs rev 一致時に限られ darwin でフルビルドになる
    llm-agents.url = "github:numtide/llm-agents.nix";
    # nixpkgs は follows しない: unstable(26.11)が x86_64-darwin を落としており、
    # hunk 内部の flake-parts が全 system を評価すると throw するため（hunk 自前の lock を使う）
    hunk.url = "github:modem-dev/hunk/v0.17.3";

    # 外部 skills（flake = false で pin。nix/home/agents/skills.nix の external から参照）
    natural-japanese = {
      url = "github:coji/natural-japanese";
      flake = false;
    };
  };

  # 本機では効かない（daemon の trusted-users = root のため無視される）。
  # 実効的な配布は darwin-shared.nix の nix.settings と CI の extra_nix_config。
  # 他者がこの flake を使う場合への案内として維持する
  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
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
          packages = {
            herdr = pkgs.callPackage ./nix/overlays/herdr.nix { };
            zabrze = pkgs.callPackage ./nix/overlays/zabrze.nix { };
          };

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
            (import ./nix/overlays)
            # hunk は overlay 未 export のためインライン overlay で pkgs.hunk へ橋渡しする
            (_: prev: {
              hunk = inputs.hunk.packages.${prev.stdenv.hostPlatform.system}.hunk;
              # llm-agents は packages.${system} を直接参照する（overlay 経由だと自前 nixpkgs で再ビルドされキャッシュが効かない）
              llm-agents = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system};
            })
          ];

          allowedUnfree = [
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
                      inherit inputs username;
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
                inherit inputs username;
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
