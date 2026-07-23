{ pkgs, lib, ... }:
{
  home.activation.rustup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.rustup}/bin/rustup default stable
    run ${pkgs.rustup}/bin/rustup component add rust-analyzer
  '';

  home.packages = with pkgs; [
    awscli2
    delta
    duckdb
    gh
    ghq
    git
    google-cloud-sdk
    hadolint
    harlequin
    hunk
    lazydocker
    lazygit
    mise
    mkcert
    pgcli
    postgresql
    rustup
    sqldiff
    sqlite
    ssm-session-manager-plugin
    tenv
    yq-go
  ];
}
