let
  swayimgWrapper =
    inputs:
    inputs.wrappers.lib.wrapModule (
      {
        config,
        wlib,
        lib,
        ...
      }:
      {
        imports = [ wlib.modules.default ];

        options = {
          settings = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = "Swayimg config settings in lua";
          };

          swayimgLua = lib.mkOption {
            type = wlib.types.file config.pkgs;
            default.content = lib.concatLines [
              (builtins.readFile ./init.lua)
              config.settings
            ];
            visible = false;
          };
        };

        config.package = lib.mkDefault config.pkgs.swayimg;
        config.runtimePkgs = [
          config.pkgs.wl-clipboard # wl-copy
        ];

        config.constructFiles = {
          generatedConfig = {
            relPath = "swayimg.lua";
            content = lib.concatLines [
              (builtins.readFile ./swayimg.lua)
              config.settings
            ];
          };
        };

        config.flags = {
          "--config" = config.constructFiles.generatedConfig.path;
        };
      }
    );
in
{
  tags = [ "gui" ];

  packages =
    { inputs, pkgs, ... }:
    {
      swayimg = (swayimgWrapper inputs).wrap { inherit pkgs; };
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
