{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bash-language-server
    copilot-language-server
    delve
    golangci-lint
    gopls
    lua-language-server
    markdownlint-cli
    nixd
    prettier
    prisma-language-server
    selene
    shellcheck
    shfmt
    stylua
    tailwindcss-language-server
    terraform-ls
    vscode-langservers-extracted
    vtsls
    yaml-language-server
  ];
}
