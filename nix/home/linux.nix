{ pkgs, lib, ... }:
lib.mkIf pkgs.stdenv.isLinux {
  targets.genericLinux.enable = lib.mkDefault true;

  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    ghostty
    trash-cli
    wezterm

    # Fonts
    hackgen-font
    hackgen-nf-font
    plemoljp
    plemoljp-nf
    plemoljp-hs
    moralerspace
    moralerspace-hw
  ];

  # macOS は Finder の30日自動削除に任せるため Linux のみ
  systemd.user.services.trash-empty = {
    Unit.Description = "Purge trash older than 30 days";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.trash-cli}/bin/trash-empty -f 30";
    };
  };
  systemd.user.timers.trash-empty = {
    Unit.Description = "Daily trash purge";
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
