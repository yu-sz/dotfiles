{ pkgs, ... }:
{
  home.packages = with pkgs; [
    awscli2
    ghq
    google-cloud-sdk
    hadolint
    lazydocker
    mkcert
    mise
    pgcli
    postgresql
    sqldiff
    ssm-session-manager-plugin
    tenv
  ];
}
