{ pkgs, ... }:
{
  imports = [
    ./claude-code.nix
    ./codex.nix
    ./gemini-cli.nix
    ./skills.nix
    ./sync.nix
  ];

  home.packages = with pkgs.llm-agents; [
    claude-code
    codex
    gemini-cli
  ];
}
