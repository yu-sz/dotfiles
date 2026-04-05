{ pkgs, ... }:
{
  home.packages = with pkgs; [
    prettier
    stylua
    shfmt
  ];
}
