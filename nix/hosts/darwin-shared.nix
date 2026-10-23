{ pkgs, username, ... }:
{
  imports = [ ./darwin-aerospace.nix ];

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      extra-substituters = [ "https://cache.numtide.com" ];
      extra-trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
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
    brews = [
      "curl"
      "ca-certificates"
    ];
    onActivation = {
      autoUpdate = false;
      cleanup = "uninstall";
      upgrade = false;
    };
    casks = [
      "alt-tab"
      "dbeaver-community"
      "google-japanese-ime"
      "karabiner-elements"
      "orbstack"
      "raycast"
      "wezterm"
    ];
  };

  nix-homebrew = {
    enable = true;
    user = username;
    autoMigrate = true;
  };

  security.pki.caCertificateBlacklist = [
    "Comodo AAA Services root"
    "emSign ECC Root CA - G3"
  ];

  environment = {
    etc."homebrew/brew.env".text = ''
      HOMEBREW_FORCE_BREWED_CURL=1
      HOMEBREW_FORCE_BREWED_CA_CERTIFICATES=1
    '';

    variables = {
      # nix-darwinのデフォルトはEDITOR=nano。/etc/zshenvのset-environment経由で
      # ビルド時のzshサブプロセスにも伝播するため、zabrzeのテスト等に影響する
      EDITOR = "vim";
      SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
      PIP_CERT = "/etc/ssl/certs/ca-certificates.crt";
      AWS_CA_BUNDLE = "/etc/ssl/certs/ca-certificates.crt";
      REQUESTS_CA_BUNDLE = "/etc/ssl/certs/ca-certificates.crt";
      CLOUDSDK_CORE_CUSTOM_CA_CERTS_FILE = "/etc/ssl/certs/ca-certificates.crt";
    };
  };

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
    finder.FXRemoveOldTrashItems = true;
  };
}
