{ pkgs, lib, ... }:
{
  home.activation = {
    miseReshim = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run ${pkgs.coreutils}/bin/env PATH="${pkgs.mise}/bin:$PATH" \
        ${pkgs.mise}/bin/mise --cd "$HOME" reshim --force
    '';

    rustup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${pkgs.rustup}/bin/rustup default stable
      run ${pkgs.rustup}/bin/rustup component add rust-analyzer
    '';
  };

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
