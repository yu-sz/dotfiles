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

    # eMudhra 中間 CA 鍵漏出（CVE-2026-111943）対応。/usr/bin/git や /usr/bin/python3（LibreSSL）は SSL_CERT_FILE を無視して
    # Apple 同梱の /etc/ssl/cert.pem を使い、このファイルは macOS アップデートで元に戻るため、nrs のたびに該当ルートを外す。
    # 手順は https://support.apple.com/en-us/149555 に準拠。Apple が修正版の cert.pem を同梱したら削除する
    activationScripts.postActivation.text =
      let
        compromisedRoots = pkgs.writeText "emudhra-compromised-roots" ''
          === /C=IN/OU=emSign PKI/O=eMudhra Technologies Limited/CN=emSign ECC Root CA - G3
          === /C=GB/ST=Greater Manchester/L=Salford/O=Comodo CA Limited/CN=AAA Certificate Services
        '';
      in
      ''
        if /usr/bin/grep -qxFf ${compromisedRoots} /etc/ssl/cert.pem; then
          echo "removing compromised eMudhra roots from /etc/ssl/cert.pem..." >&2
          tmp=$(/usr/bin/mktemp)
          if ! {
            /usr/bin/awk 'NR == FNR { drop[$0]; next } /^(===|###) / { skip = 0 } ($0 in drop) { skip = 1 } !skip' \
              ${compromisedRoots} /etc/ssl/cert.pem > "$tmp" \
              && [ -s "$tmp" ] \
              && /bin/cp -p /etc/ssl/cert.pem /etc/ssl/cert.pem.orig \
              && /usr/bin/install -m 0644 -o root -g wheel "$tmp" /etc/ssl/cert.pem
          }; then
            echo "warning: failed to remove compromised eMudhra roots from /etc/ssl/cert.pem" >&2
          fi
          /bin/rm -f "$tmp"
        fi
      '';
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
