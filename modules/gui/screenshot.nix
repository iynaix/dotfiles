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
          "Mod+backslash" = "spawn focal image --area selection --no-notify --no-save";
          "Mod+Shift+backslash" = "spawn focal image --menu";
          "Mod+Ctrl+backslash" = "spawn focal image --area selection --ocr";
          "Alt+backslash" = "spawn focal video --menu";
        };
      };
    };
}
