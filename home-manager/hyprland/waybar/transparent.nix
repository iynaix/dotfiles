{
  config,
  lib,
  ...
}: let
  cfg = config.iynaix.waybar;
in {
  config = lib.mkIf (cfg.enable && cfg.theme == "transparent") {
    iynaix.waybar.config = {
      margin = lib.mkForce "0";
      clock = {
        format = lib.mkForce "󰥔   {:%H:%M}";
        format-alt = lib.mkForce "󰸗  {:%a, %d %b %Y}";
      };
    };

    iynaix.wallust.entries = {
      "waybar.css" = let
        radius = "0";
        baseModuleCss = ''
          font-family: "Inter";
          font-weight: bold;
          color: {foreground};
          transition: none;
          text-shadow: 1px 1px 2px rgba(0,0,0,0.8);
          border-bottom:  2px solid transparent;
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
                if (i == 0)
                then ''
                  padding-right: 12px;
                ''
                else if (i == last)
                then ''
                  padding-left: 12px;
                ''
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
        enable = cfg.enable && cfg.theme == "transparent";
        text = ''
          #waybar {
            background: rgba(0,0,0,0.3)
          }

          ${mkModuleCss cfg.config.modules-left}
          ${mkModuleCss cfg.config.modules-center}
          ${mkModuleCss cfg.config.modules-right}

          #workspaces button {
            ${baseModuleCss}
          }

          #custom-nix {
            margin-left: 12px;
            font-size: 20px;
          }

          #clock{
            margin-right: 12px;
          }

          #workspaces button.active {
            margin-right: 4px;
            border-bottom:  2px solid {foreground};
            background-color: rgba(255,255,255, 0.25);
            border-radius: 0;
          }
        '';
        target = "~/.config/waybar/style.css";
      };
    };
  };
}
