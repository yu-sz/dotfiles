{ lib, config, ... }:
let
  cfg = config.services.aerospace;
in
{
  services.aerospace = {
    enable = true;
    settings = { };
  };

  launchd.user.agents.aerospace.command =
    lib.mkForce "${cfg.package}/Applications/AeroSpace.app/Contents/MacOS/AeroSpace --config-path $HOME/.config/aerospace/aerospace.toml";
}
