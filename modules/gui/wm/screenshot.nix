{ inputs, lib, ... }:
{
  flake.modules.nixos.wm =
    { config, pkgs, ... }:
    let
      focal = inputs.focal.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      environment.systemPackages = [
        pkgs.swappy
        focal
      ];

      # swappy conf
      hj.xdg.config.files."swappy/config" = {
        generator = lib.generators.toINI { };
        value = {
          default = {
            save_dir = "${config.hj.directory}/Pictures/Screenshots";
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
      };

      custom = {
        wm.binds = {
          "Mod+backslash".spawn = "focal image --area selection --no-notify --no-save --no-rounded-windows";
          "Mod+Shift+backslash".spawn = "focal image --rofi";
          "Mod+Ctrl+backslash".spawn = "focal image --area selection --ocr";
          "Alt+backslash".spawn = "focal video --rofi";
        };

        programs.niri.settings.binds = {
          # use the built in niri screenshot
          "Mod+backslash" = lib.mkForce {
            screenshot = _: {
              props = {
                show-pointer = false;
              };
            };
          };
        };
      };
    };
}
