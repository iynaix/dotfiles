{
  config,
  lib,
  ...
}: let
  cfg = config.iynaix.waybar;
in {
  config = lib.mkIf (cfg.enable && cfg.theme == "split") {
    iynaix.wallust.entries = {
      "waybar.css" = let
        radius = cfg.border-radius;
        baseModuleCss = ''
          font-family: "Inter";
          font-weight: bold;
          color: {foreground};
          background-color: {color0};
          transition: none;
          padding: 0 8px;
        '';
        mkModuleCss = arr: let
          last = builtins.length arr - 1;
        in
          lib.concatStringsSep "\n" (
            lib.imap0 (i: mod: let
              className = builtins.replaceStrings ["hyprland/" "/"] ["" "-"] mod;
              left =
                if i == 0
                then radius
                else "0";
              right =
                if i == last
                then radius
                else "0";
              padding =
                if (i == 0 || i == last)
                then ""
                else ''
                  padding-left: 12px;
                  padding-right: 12px;
                '';
            in ''
              #${className} {
                ${baseModuleCss}
                border-radius: ${left} ${right} ${right} ${left};
                ${padding}
              }'')
            arr
          );
      in {
        enable = config.iynaix.wallust.waybar;
        text = ''
          #waybar {
            background: transparent;
          }

          ${mkModuleCss cfg.finalConfig.modules-left}
          ${mkModuleCss cfg.finalConfig.modules-center}
          ${mkModuleCss cfg.finalConfig.modules-right}

          #workspaces button {
            ${baseModuleCss}
          }

          #workspaces, #workspaces button {
            padding: 0 4px 0 4px;
          }

          #clock, #workspaces button.active {
            background-color: {foreground};
            color: {color0};
            margin-right: 4px;
          }

          #custom-nix {
            background-color: {foreground};
            color: {color0};
            margin-left: 4px;
            padding: 0 16px 0 12px;
            font-size: 16px;
          }

          #workspaces button.urgent {
            background-color: {color1};
            color: {foreground};
          }

          #network.disconnected, #battery.discharging.critical {
            color: {color1};
          }

          /* invert colors for monocle / swallowing */
          window#waybar.fullscreen #window, window#waybar.swallowing #window, window#waybar.hidden #window {
              background-color: {foreground};
              color: {color0};
          }

          #workspaces button.active {
            border-radius: 50%;
          }

          tooltip {
            background: {color0};
          }
        '';
        target = "~/.config/waybar/style.css";
      };
    };
  };
}
