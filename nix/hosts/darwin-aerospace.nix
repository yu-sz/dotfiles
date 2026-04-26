{ pkgs, ... }:
{
  services.aerospace = {
    enable = true;

    settings = {
      exec = {
        inherit-env-vars = true;
        env-vars.PATH = "${pkgs.sketchybar}/bin:${pkgs.coreutils}/bin:\${PATH}";
      };

      after-startup-command = [ "exec-and-forget sketchybar" ];

      exec-on-workspace-change = [
        "/bin/bash"
        "-c"
        "sketchybar --trigger aerospace_workspace_change FOCUSED=$AEROSPACE_FOCUSED_WORKSPACE"
      ];

      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";
      enable-normalization-flatten-containers = true;
      enable-normalization-opposite-orientation-for-nested-containers = true;
      on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];

      gaps = {
        inner = {
          horizontal = 8;
          vertical = 8;
        };
        outer = {
          left = 8;
          bottom = 8;
          top = 52;
          right = 8;
        };
      };

      mode = {
        main.binding = {
          alt-h = "focus left";
          alt-j = "focus down";
          alt-k = "focus up";
          alt-l = "focus right";

          alt-shift-h = "move left";
          alt-shift-j = "move down";
          alt-shift-k = "move up";
          alt-shift-l = "move right";

          alt-1 = "workspace 1";
          alt-2 = "workspace 2";
          alt-3 = "workspace 3";
          alt-4 = "workspace 4";

          alt-shift-1 = "move-node-to-workspace 1";
          alt-shift-2 = "move-node-to-workspace 2";
          alt-shift-3 = "move-node-to-workspace 3";
          alt-shift-4 = "move-node-to-workspace 4";

          alt-tab = "workspace-back-and-forth";
          alt-slash = "layout tiles horizontal vertical";
          alt-comma = "layout accordion horizontal vertical";
          alt-shift-space = "layout floating tiling";
          alt-shift-semicolon = "mode service";
          alt-r = "mode resize";
        };

        service.binding = {
          esc = [
            "reload-config"
            "mode main"
          ];
          r = [
            "flatten-workspace-tree"
            "mode main"
          ];
          f = [
            "layout floating tiling"
            "mode main"
          ];
          backspace = [
            "close-all-windows-but-current"
            "mode main"
          ];
        };

        resize.binding = {
          h = "resize width -50";
          j = "resize height +50";
          k = "resize height -50";
          l = "resize width +50";
          equal = "balance-sizes";
          esc = "mode main";
        };
      };

      on-window-detected = [
        {
          "if".app-id = "com.google.Chrome";
          run = [ "move-node-to-workspace 1" ];
        }
        {
          "if".app-id = "company.thebrowser.Browser";
          run = [ "move-node-to-workspace 1" ];
        }
        {
          "if".app-id = "com.apple.Safari";
          run = [ "move-node-to-workspace 1" ];
        }
        {
          "if".app-id = "com.tinyspeck.slackmacgap";
          run = [ "move-node-to-workspace 4" ];
        }
      ];
    };
  };
}
