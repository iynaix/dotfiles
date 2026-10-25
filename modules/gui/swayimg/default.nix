{
  tags = [ "gui" ];

  packages =
    { inputs, pkgs, ... }:
    let
      swayimgWrapper = import ./_wrapper.nix { inherit inputs; };
    in
    {
      swayimg = swayimgWrapper.wrap { inherit pkgs; };
    };

  config =
    {
      pkgs,
      ...
    }:
    let
      swayimg' = pkgs.custom.swayimg.wrap {
        # additional settings that reference local filepaths or applications that aren't installed by default
        settings = builtins.readFile ./extra.lua;
      };
    in
    {
      environment.systemPackages = [
        swayimg'
      ];

      xdg.mime.defaultApplications = {
        "image/jpeg" = "swayimg.desktop";
        "image/gif" = "swayimg.desktop";
        "image/webp" = "swayimg.desktop";
        "image/png" = "swayimg.desktop";
      };

      custom.programs.print-config = {
        swayimg = /* sh */ ''moor --lang lua "${swayimg'.configuration.constructFiles.generatedConfig.outPath}"'';
      };
    };
}
