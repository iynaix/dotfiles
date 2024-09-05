{
  config,
  isNixOS,
  lib,
  pkgs,
  ...
}:
let
  focal = pkgs.custom.focal.override {
    hyprland = config.wayland.windowManager.hyprland.package;
    rofi = config.programs.rofi.package;
    ocr = true;
  };
in
lib.mkIf config.custom.hyprland.enable {
  home.packages = lib.mkIf isNixOS (
    [ focal ]
    ++ (with pkgs; [
      swappy
      wf-recorder
    ])
  );

  # swappy conf
  xdg.configFile."swappy/config".text = lib.generators.toINI { } {
    default = {
      save_dir = "${config.xdg.userDirs.pictures}/Screenshots";
      save_filename_format = "%Y-%m-%dT%H:%M:%S%z.png";
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
      "$mod, backslash, exec, ${lib.getExe focal} --area selection --no-notify --no-save"
      ''$mod_SHIFT, backslash, exec, ${lib.getExe focal} --rofi''
      "$mod_CTRL, backslash, exec, ${lib.getExe focal} --area selection --ocr"
      ''ALT, backslash, exec, ${lib.getExe focal} --rofi --video''
    ];
  };
}
