{ pkgs, lib, ... }:
{
  home.activation.rustup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.rustup}/bin/rustup default stable
    run ${pkgs.rustup}/bin/rustup component add rust-analyzer
  '';

  home.packages = with pkgs; [
    awscli2
    delta
    gh
    ghq
    git
    google-cloud-sdk
    hadolint
    lazydocker
    lazygit
    mkcert
    pgcli
    postgresql
    rustup
    sqldiff
    ssm-session-manager-plugin
    tenv
  ];
}
