{ lib, ... }:
let
  hyprlandOptions = {
    settings = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Hyprland lua config";
    };
  };
in
{
  flake.wrappers.hyprland =
    {
      config,
      wlib,
      ...
    }:
    {
      imports = [ wlib.modules.default ];

      options = hyprlandOptions // {
        "hyprland.lua" = lib.mkOption {
          type = wlib.types.file config.pkgs;
          default.path = config.constructFiles.generatedConfig.path;
          default.content = "";
          visible = false;
        };
      };

      config.package = lib.mkDefault config.pkgs.hyprland;

      config.constructFiles.generatedConfig = {
        relPath = "hyprland.lua";
        content = config.settings;
      };

      # validate hyprland config, filter out source to non-existent file
      # can be removed when the PR is merged:
      # https://github.com/hyprwm/Hyprland/pull/12286
      config.drv.installPhase = /* sh */ ''
        runHook preInstall
        export XDG_RUNTIME_DIR=$(mktemp -d)
        ${lib.getExe config.package} --verify-config -c "${config.constructFiles.generatedConfig.path}"
        runHook postInstall
      '';

      config.filesToPatch = [
        "share/wayland-sessions/*.desktop"
      ];
      config.flags = {
        "--config" = config.constructFiles.generatedConfig.path;
      };
    };

  flake.modules.nixos.core = {
    options.custom = {
      programs.hyprland = hyprlandOptions;
    };
  };
}
