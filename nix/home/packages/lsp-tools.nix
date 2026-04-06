{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bash-language-server
    copilot-language-server
    delve
    golangci-lint
    gopls
    lua-language-server
    selene
    markdownlint-cli
    nixd
    prettier
    prisma-language-server
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
