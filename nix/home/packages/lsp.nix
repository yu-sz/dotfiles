{ pkgs, ... }:
{
  home.packages = with pkgs; [
    vtsls
    lua-language-server
    bash-language-server
    vscode-langservers-extracted
    tailwindcss-language-server
    typescript-language-server
    terraform-ls
    yaml-language-server
    prisma-language-server
    copilot-language-server
    nixd
  ];
}
