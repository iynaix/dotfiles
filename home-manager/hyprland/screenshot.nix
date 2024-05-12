{
  config,
  isNixOS,
  lib,
  pkgs,
  ...
}:
let
  screenshotDir = "${config.xdg.userDirs.pictures}/Screenshots";
  iso8601 = "%Y-%m-%dT%H:%M:%S%z";
in
lib.mkIf config.wayland.windowManager.hyprland.enable {
  home.packages = lib.mkIf isNixOS (
    with pkgs;
    [
      grimblast
      swappy
    ]
  );

  custom.shell.packages = {
    # screenshot with  options to preselect
    hypr-screenshot = {
      runtimeInputs = with pkgs; [
        grimblast
        libnotify
        swappy
        rofi-wayland
      ];
      text = lib.replaceStrings [ "@outputPath@" ] [ "${screenshotDir}/$(date +${iso8601}).png" ] (
        lib.readFile ./screenshot.sh
      );
    };
    # run ocr on selected area and copy to clipboard
    hypr-ocr = {
      runtimeInputs = with pkgs; [
        grimblast
        libnotify
        tesseract5
      ];
      text = ''
        img="${screenshotDir}/ocr.png"

        grimblast save area "$img"
        teserract5 "$img" - | wl-copy
        rm "$img"
        notify-send "$(wl-paste)"
      '';
    };
  };

  # swappy conf
  xdg.configFile."swappy/config".text = lib.generators.toINI { } {
    default = {
      save_dir = screenshotDir;
      save_filename_format = "${iso8601}.png";
      show_panel = false;
      line_size = 5;
      text_size = 20;
      text_font = "sans-serif";
      paint_mode = "brush";
      early_exit = false;
      fill_shape = false;
    };
  };

  wayland.windowManager.hyprland.settings = {
    bind = [
      "$mod, backslash, exec, grimblast --notify copy area"
      "$mod_SHIFT, backslash, exec, hypr-screenshot"
      "$mod_CTRL, backslash, exec, hypr-ocr"
    ];
  };
}
