{ inputs, ... }:
inputs.wrappers.lib.wrapModule (
  {
    config,
    pkgs,
    wlib,
    lib,
    ...
  }:
  let
    tomlFmtType = wlib.types.structuredValueWith {
      nullable = false;
      typeName = "TOML";
    };
  in
  {
    imports = [
      wlib.modules.default
      wlib.modules.systemd
    ];

    options = {
      settings = lib.mkOption {
        description = ''
          Umbirel configuration settings.
          See <https://docs.noctalia.dev/umbriel/configuration/>
        '';
        default = { };
        type = lib.types.submodule {
          freeformType = tomlFmtType;
        };
        example = lib.literalMD ''
          ```nix
          general = {
            autostart = ["kitty"];
            focus_on_activate = true;
            honor_restored_maximize = false;
            show_cheatsheet = false;
            xwayland = true;
          };
          ```
        '';
      };

      includeOptional = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Optional includes for Umbriel
          See <https://docs.noctalia.dev/umbriel/configuration/?section=include#include>
        '';
        example = lib.literalMD ''
          [
            "~/.config/umbriel/noctalia.toml",
          ]
        '';
      };

      "config.toml" = lib.mkOption {
        type = wlib.types.file {
          path = lib.mkOptionDefault config.constructFiles.generatedConfig.path;
        };
        default = { };
        description = ''
          Configuration file for Umbriel.
          See <https://docs.noctalia.dev/umbriel/configuration/>

          If `config."config.toml".content` is non-empty, its content will be used instead of the generated
          config from `config.settings` in the generated config file in the derivation.

          You may also set `config."config.toml".path` to your own path.

          This will still allow the generated config to be created from `config.settings`

          You could use the include feature to include it.
        '';
        example = lib.literalMD ''
          ```nix
          # Overwrite the generated config
          config."config.toml".content = /* toml */ '''
            [general]
            autostart = ["kitty"]
            focus_on_activate = true
            honor_restored_maximize = false
            show_cheatsheet = false
            xwayland = true
          ''';
          ```
        '';
      };

      disableConfigValidation = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          When `true`, the wrapper will not run `umbriel config validate` on the nix-provided config file.

          This is useful for debugging the output of the generated config file.

          It also allows you to pass an impure path via `config."config.toml".path`,
          as nix no longer needs to know about this path at build time.
        '';
      };

      disableConfigHotReload = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          When `true`, the wrapper will not hot reload umbriel with the new config on rebuild.
        '';
      };
    };

    config.package = lib.mkDefault pkgs.umbriel;

    config.flags = {
      "-c" = config.constructFiles.generatedConfig.path;
    };

    config.filesToPatch = [
      "lib/systemd/user/umbriel.service"
      "share/systemd/user/umbriel.service"
      "share/wayland-sessions/umbriel.desktop"
    ];

    config.drv.installPhase = lib.mkIf (!config.disableConfigValidation) ''
      runHook preInstall
      ${lib.getExe config.package} config validate -c ${config.constructFiles.generatedConfig.path}
      runHook postInstall
    '';

    # User supplied settings are written to a separate file before being included in a
    # minimal wrapper file with just includes.
    # This is so files in includeOptional are able to override settings within the
    # user config; otherwise the including file takes priority over any other settings, see:
    # https://docs.noctalia.dev/umbriel/configuration/?section=include#include
    config.constructFiles.userConfig =
      if config."config.toml".content or "" != "" then
        {
          relPath = "${config.binName}-user-config.toml";
          content = config."config.toml".content;
        }
      else
        {
          relPath = "${config.binName}-user-config.toml";
          builder = ''${pkgs.remarshal}/bin/json2toml "$1" "$2"'';
          content = builtins.toJSON config.settings;
        };

    config.constructFiles.generatedConfig = {
      relPath = "${config.binName}-config.lua";
      builder = ''${pkgs.remarshal}/bin/json2toml "$1" "$2"'';
      content = builtins.toJSON {
        include = {
          files = [ config.constructFiles.userConfig.path ];
          optional.files = config.includeOptional;
        };
      };
    };

    config.systemd.user.service.umbriel = lib.mkIf (!config.disableConfigHotReload) {
      Unit.X-Reload-Triggers = [ "${config.constructFiles.generatedConfig.path}" ];
      Service = {
        ExecReload = "${lib.getExe config.package} config-replace ${config.constructFiles.generatedConfig.path}";
        X-ReloadIfChanged = true;
      };
    };

    config.meta.platforms = lib.platforms.linux;
    config.passthru.providedSessions = pkgs.umbriel.passthru.providedSessions;
  }
)
