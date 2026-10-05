{ inputs, ... }:
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
)
