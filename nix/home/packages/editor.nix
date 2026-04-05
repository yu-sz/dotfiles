{ pkgs, ... }:
{
  home.packages = with pkgs; [
    claude-code
    mise
    sheldon
    tenv
  ];
}
