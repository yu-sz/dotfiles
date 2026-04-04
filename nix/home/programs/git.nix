_: {
  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
      user.useConfigOnly = true;
      ghq.root = "~/Projects";
      fetch.prune = true;
    };
    ignores = [
      ".DS_Store"
      "._*"
      "node_modules/"
      "*.log"
      ".bundle/"
      "*.local"
      "*.local.*"
    ];
    includes = [
      { path = "~/.config/git/config.local"; }
    ];
  };
}
