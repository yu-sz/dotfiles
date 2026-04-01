_: {
  programs.delta = {
    enable = true;
    enableGitIntegration = false;
    options = {
      side-by-side = true;
      line-numbers = true;
      navigate = true;
      plus-style = "syntax #043103";
      minus-style = "syntax #8D3043";
      syntax-theme = "Monokai Extended";
    };
  };
}
