{ lib, ... }:
{
  programs.lazygit = {
    enable = true;
    settings = {
      git.pagers = [
        {
          colorArg = "always";
          pager = "delta --dark --paging=never";
        }
      ];
      gui = {
        language = "ja";
        nerdFontsVersion = "3";
        sidePanelWidth = 0.15;
        showIcons = true;
        theme = {
          selectedLineBgColor = lib.mkForce [ "underline" ];
        };
      };
      refresher.refreshInterval = 3;
      os.editPreset = "nvim-remote";
    };
  };
}
