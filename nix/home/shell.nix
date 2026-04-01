_: {
  home.shell.enableZshIntegration = false;

  programs.direnv = {
    enable = true;
    silent = true;
    nix-direnv.enable = true;
  };
}
