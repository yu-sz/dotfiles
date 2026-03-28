{ pkgs, username, ... }:
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.gc = {
    automatic = true;
    interval = { Weekday = 7; Hour = 3; Minute = 0; };
    options = "--delete-older-than 30d";
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "uninstall";
      upgrade = false;
    };
    casks = [
      "raycast"
      "ghostty"
      "wezterm"
      "warp"
      "docker-desktop"
      "dbeaver-community"
      "karabiner-elements"
      "visual-studio-code"
      "cursor"
      "cursor-cli"
    ];
  };

  nix-homebrew = {
    enable = true;
    user = username;
    autoMigrate = true;
  };

  # nix-darwinのデフォルトはEDITOR=nano。/etc/zshenvのset-environment経由で
  # ビルド時のzshサブプロセスにも伝播するため、zabrzeのテスト等に影響する
  environment.variables.EDITOR = "vim";

  system.primaryUser = username;
  users.users.${username}.home = "/Users/${username}";

  fonts.packages = with pkgs; [
    hackgen-font
    hackgen-nf-font
    plemoljp
    plemoljp-nf
    plemoljp-hs
    moralerspace
    moralerspace-hw
  ];

  system.stateVersion = 6;
}
