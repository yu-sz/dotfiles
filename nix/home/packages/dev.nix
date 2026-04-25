{ pkgs, lib, ... }:
{
  home.activation.rustup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.rustup}/bin/rustup default stable
    run ${pkgs.rustup}/bin/rustup component add rust-analyzer
  '';

  home.packages = with pkgs; [
    awscli2
    ghq
    google-cloud-sdk
    hadolint
    lazydocker
    mkcert
    pgcli
    postgresql
    rustup
    sqldiff
    ssm-session-manager-plugin
    tenv
  ];
}
