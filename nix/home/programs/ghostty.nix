_: {
  programs.ghostty = {
    enable = true;
    package = null;
    settings = {
      font-family = "\"Moralerspace Xenon HW\"";
      window-title-font-family = "\"Moralerspace Xenon HW\"";
      font-size = 18;
      font-thicken = false;
      theme = "tokyonight";
      background-opacity = 0.85;
      background-blur-radius = 20;
      unfocused-split-opacity = 0.7;
      cursor-opacity = 0.8;
      cursor-color = "#ffffff";
      cursor-style = "block";
      window-theme = "auto";
      window-padding-color = "background";
      window-padding-x = 2;
      window-padding-y = 2;
      window-padding-balance = true;
      window-step-resize = false;
      window-save-state = "always";
      window-inherit-working-directory = true;
      macos-icon = "xray";
      macos-titlebar-style = "hidden";
      clipboard-read = "allow";
      clipboard-write = "allow";
      clipboard-trim-trailing-spaces = true;
      shell-integration = "detect";
      command = "/bin/zsh -lic 'ghostty +boo; tmux attach || tmux new-session -s default'";
      keybind = [ "shift+enter=text:\\n" ];
    };
  };
}
