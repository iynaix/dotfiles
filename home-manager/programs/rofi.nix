{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.iynaix.rofi;
in {
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
  };

  home.packages = with pkgs; [rofi-power-menu];

  xdg.configFile = {
    "rofi/rofi-wifi-menu" = lib.mkIf config.iynaix.wifi.enable {
      source = ./rofi-wifi-menu.sh;
    };

    "rofi/config.rasi".text = ''
      @theme "~/.cache/wallust/rofi.rasi"
    '';
  };

  iynaix.rofi.launcher = {
    style = "2-2";
  };

  iynaix.wallust.entries."rofi.rasi" = let
    themeRasi = "${pkgs.iynaix.rofi-themes}/colors/${toString cfg.launcher.theme}.rasi";
    launcherRasi = "${pkgs.iynaix.rofi-themes}/launchers/type-${builtins.replaceStrings ["-"] ["/style-"] cfg.launcher.style}.rasi";
  in {
    enable = config.programs.rofi.enable;
    # replace the imports
    text = ''
      @import "${themeRasi}"
      * {
        width: ${toString cfg.width}px;
      }
      ${builtins.replaceStrings ["@import"] ["// @import"] (builtins.readFile launcherRasi)}
    '';
    target = "~/.cache/wallust/rofi.rasi";
  };

  # TODO: powermenu
  # 1-1
  # 1-5
  # 3-3
  # 4-2
  # 4-3
  # 4-5
  # 5-1 image?
  # 6-1 image?
  # 6-3 image?
}
