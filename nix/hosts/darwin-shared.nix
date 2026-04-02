{ pkgs, username, ... }:
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.gc = {
    automatic = true;
    interval = {
      Weekday = 7;
      Hour = 3;
      Minute = 0;
    };
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
      "google-japanese-ime"
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
    defaults = {
      dock = {
        orientation = "right";
        autohide = false;
        autohide-delay = 0.0;
        autohide-time-modifier = 0.0;
      };
      finder = {
        ShowPathbar = true;
        AppleShowAllExtensions = true;
        FXPreferredViewStyle = "Nlsv";
      };
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        "com.apple.swipescrolldirection" = false;
        "com.apple.trackpad.forceClick" = true;
        "com.apple.trackpad.scaling" = 2.0;
      };
      menuExtraClock = {
        Show24Hour = true;
        ShowSeconds = true;
      };
      CustomUserPreferences = {
        NSGlobalDomain = {
          "com.apple.mouse.scaling" = 2;
          "com.apple.mouse.doubleClickThreshold" = 1.1;
          "com.apple.scrollwheel.scaling" = 0.215;
        };
        "com.apple.dock".show-recents = false;
        "com.apple.finder" = {
          ShowExternalHardDrivesOnDesktop = false;
          ShowHardDrivesOnDesktop = false;
          ShowMountedServersOnDesktop = false;
          ShowRemovableMediaOnDesktop = false;
        };
      };
    };
    activationScripts.postActivation.text = ''
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';
    stateVersion = 6;
  };

  users.users.${username}.home = "/Users/${username}";

  stylix = {
    enable = true;
    autoEnable = false;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";
    fonts.monospace = {
      package = pkgs.moralerspace-hw;
      name = "Moralerspace Xenon HW";
    };
  };

  fonts.packages = with pkgs; [
    hackgen-font
    hackgen-nf-font
    plemoljp
    plemoljp-nf
    plemoljp-hs
    moralerspace
    moralerspace-hw
  ];
}
