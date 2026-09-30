{
  tags = [ "wm" ];

  config =
    {
      inputs,
      system,
      ...
    }:
    let
      focal = inputs.focal.packages.${system}.default;
    in
    {
      environment.systemPackages = [
        focal
      ];

      custom = {
        programs.umbriel.settings.keybinds = {
          "Mod+backslash" =
            "spawn:focal image --noctalia --area selection --no-notify --no-save --no-rounded-windows";
          "Mod+Shift+backslash" = "spawn:focal image --noctalia --rofi";
          "Mod+Ctrl+backslash" = "spawn:focal image --noctalia --area selection --ocr";
          "Alt+backslash" = "spawn:focal video --rofi";
        };
      };
    };
}
