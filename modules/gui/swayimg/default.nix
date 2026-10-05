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
      lib,
      pkgs,
      ...
    }:
    {
      nixpkgs.overlays = [
        (_: prev: {
          swayimg = pkgs.custom.swayimg.wrap {
            pkgs = lib.mkForce prev;
            # additional settings that reference local filepaths or applications that aren't installed by default
            settings = builtins.readFile ./extra.lua;
          };
        })
      ];

      environment.systemPackages = with pkgs; [
        swayimg # overlay-ed above
        nomacs
      ];

      xdg.mime.defaultApplications = {
        "image/jpeg" = "swayimg.desktop";
        "image/gif" = "swayimg.desktop";
        "image/webp" = "swayimg.desktop";
        "image/png" = "swayimg.desktop";
      };

      custom.programs.print-config = {
        swayimg = /* sh */ ''moor --lang lua "${pkgs.swayimg.configuration.constructFiles.generatedConfig.outPath}"'';
      };

      custom.persist = {
        home = {
          directories = [
            ".config/nomacs"
          ];
        };
      };
    };
}
