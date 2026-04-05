{ pkgs, ... }:
{
  home.packages = with pkgs; [
    awscli2
    ghq
    jq
    pgcli
    google-cloud-sdk
    ssm-session-manager-plugin
    gitmux
    lazydocker
  ];
}
