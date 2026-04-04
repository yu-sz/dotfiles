_: {
  # zsh integrationはconfig/zsh/lazy/で手動管理するため、HMの自動生成を無効化
  home.shell.enableZshIntegration = false;

  programs.direnv = {
    enable = true;
    silent = true;
    nix-direnv.enable = true;
  };
}
