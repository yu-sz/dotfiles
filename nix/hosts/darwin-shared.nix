{ pkgs, username, ... }:
{
  imports = [ ./darwin-aerospace.nix ];

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
    };
    optimise.automatic = true;
    gc = {
      automatic = true;
      interval = {
        Weekday = 7;
        Hour = 3;
        Minute = 0;
      };
      options = "--delete-older-than 30d";
    };
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "uninstall";
      upgrade = false;
    };
    casks = [
      "alt-tab"
      "cursor"
      "cursor-cli"
      "dbeaver-community"
      "docker-desktop"
      "google-japanese-ime"
      "karabiner-elements"
      "raycast"
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

  system = {
    primaryUser = username;
    stateVersion = 6;
  };

  users.users.${username}.home = "/Users/${username}";

  fonts.packages = with pkgs; [
    hackgen-font
    hackgen-nf-font
    plemoljp
    plemoljp-nf
    plemoljp-hs
    moralerspace
    moralerspace-hw
    sketchybar-app-font
  ];

  services.jankyborders = {
    enable = true;
    style = "round";
    width = 4.0;
    hidpi = true;
    active_color = "0xff7aa2f7";
    inactive_color = "0xff414868";
  };

  system.defaults = {
    NSGlobalDomain = {
      NSAutomaticWindowAnimationsEnabled = false;
      _HIHideMenuBar = true;
    };
    dock.expose-animation-duration = 0.0;
  };
}
