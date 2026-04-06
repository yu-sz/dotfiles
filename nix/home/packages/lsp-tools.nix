{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bash-language-server
    copilot-language-server
    lua-language-server
    luaPackages.luacheck
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
