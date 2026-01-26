# adapted from the hjem-rum module:
# https://github.com/snugnug/hjem-rum/blob/main/modules/collection/desktops/niri.nix
{
  inputs,
  lib,
  ...
}:
let
  inherit (lib.types)
    listOf
    attrsOf
    anything
    str
    lines
    submodule
    nullOr
    ;

  toNiriSpawn = commands: lib.concatMapStringsSep " " (arg: "\"${arg}\"") commands;

  toNiriBinds =
    binds:
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        bind: bindOptions:
        let
          parameters = lib.pipe bindOptions.parameters [
            (lib.mapAttrs (
              _: value:
              if lib.isBool value then
                lib.boolToString value
              else if lib.isInt value then
                toString value
              else if isNull value then
                "null"
              else
                ''"${value}"''
            ))
            (lib.mapAttrsToList (name: value: "${name}=${value}"))
            (lib.concatStringsSep " ")
          ];
          action =
            let
              spawnIsNull = isNull bindOptions.spawn;
              actionIsNull = isNull bindOptions.action;
            in
            if spawnIsNull && actionIsNull then
              throw "${bind} is missing an action or spawn to perform."
            else if !spawnIsNull && !actionIsNull then
              throw "${bind} cannot be assigned both an action and a spawn. Only one may be set."
            else if spawnIsNull then
              bindOptions.action
            else
              "spawn " + toNiriSpawn bindOptions.spawn;
        in
        "${bind} ${parameters} {${action};}"
      ) binds
    );

  toNiriSpawnAtStartup =
    spawn: lib.concatMapStringsSep "\n" (commands: "spawn-at-startup " + (toNiriSpawn commands)) spawn;

  bindsModule = submodule {
    options = {
      spawn = lib.mkOption {
        type = nullOr (listOf str);
        default = null;
        example = [
          "foot"
          "-e"
          "fish"
        ];
        description = ''
          [niri's wiki]: https://yalter.github.io/niri/Configuration%3A-Key-Bindings.html

          The spawn action to run on button-press. For other actions, please see
          {option}`binds.<keybind>.action`. See [niri's wiki] for more information.
        '';
      };
      action = lib.mkOption {
        type = nullOr str;
        default = null;
        example = "focus-column-left";
        description = ''
          [niri's wiki]: https://yalter.github.io/niri/Configuration%3A-Key-Bindings.html

          The non-spawn action to run on button-press. For spawning processes, please see
          {option}`binds.<keybind>.spawn`. See [niri's wiki] for a complete list.
        '';
      };
      parameters = lib.mkOption {
        type = attrsOf anything;
        default = { };
        example = {
          allow-when-locked = true;
          cooldown-ms = 150;
        };
        description = ''
          [niri's wiki]: https://yalter.github.io/niri/Configuration%3A-Key-Bindings.html

          The parameters to append to the bind. See [niri's wiki] for a complete list.
        '';
      };
    };
  };

  mkNiriOptions = pkgs: {
    binds = lib.mkOption {
      type = attrsOf bindsModule;
      default = { };
      example = {
        "Mod+Return" = {
          spawn = [
            "foot"
            "-e"
            "fish"
          ];
          parameters = {
            allow-when-locked = true;
            cooldown-ms = 150;
          };
        };
        "Mod+D" = {
          action = "close-window";
          parameters = {
            repeat = false;
          };
        };
      };
      description = ''
        [niri's wiki]: https://yalter.github.io/niri/Configuration%3A-Key-Bindings.html

        A list of key bindings that will be added to the configuration file. See [niri's wiki] for a complete list.
      '';
    };
    spawn-at-startup = lib.mkOption {
      type = listOf (listOf str);
      default = [ ];
      example = lib.literalExpression ''
        [
          ["waybar"]
          ["alacritty" "-e" "fish"]
        ]
      '';
      description = ''
        [niri's wiki]: https://yalter.github.io/niri/Configuration%3A-Miscellaneous.html#spawn-at-startup

        A list of programs to be loaded with niri on startup. see [niri's wiki] for more details on the API.
      '';
    };
    extraVariables = lib.mkOption {
      type = inputs.hjem.hjem-lib.${pkgs.stdenv.hostPlatform.system}.envVarType;
      default = { };
      example = {
        DISPLAY = ":0";
      };
      description = ''
        [niri's wiki]: https://yalter.github.io/niri/Configuration%3A-Miscellaneous.html#environment

        Extra environmental variables to be added to Niri's `environment` node.
        This can be used to override variables set in {option}`environment.sessionVariables`.
        You can therefore set a variable to `null` to force unset it in Niri. Learn more from [niri's wiki].
      '';
    };
    config = lib.mkOption {
      type = lines;
      default = "";
      example = lib.literalExpression ''
        screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

        switch-events {
          tablet-mode-on { spawn "bash" "-c" "gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled true"; }
          tablet-mode-off { spawn "bash" "-c" "gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled false"; }
        }
      '';
      description = ''
        [niri's wiki]: https://yalter.github.io/niri/Configuration%3A-Introduction.html

        Lines of KDL code that are added to {file}`$XDG_CONFIG_HOME/niri/config.kdl`.
        See a full list of options in [niri's wiki].
        To add to environment, please see {option}`extraVariables`.

        Here's an example of adding a file to your niri configuration:

        ```nix
          config = builtins.readFile ./config.kdl;
        ```

        Optionally, you can split your niri configuration into multiple KDL files like so:

        ```nix
          config = (lib.concatMapStringsSep "\n" builtins.readFile [./config.kdl ./binds.kdl]);
        ```

        Finally, if you need to interpolate some Nix variables into your configuration:

        ```nix
          config = builtins.readFile ./config.kdl
            +
            /* kdl */
            '''
              focus-ring {
                active-color ''${config.local.colors.border-active}
              }
            ''';
        ```
      '';
    };
  };

in
{
  flake.wrapperModules.niri = inputs.wrappers.lib.wrapModule (
    { config, wlib, ... }:
    let
      cfg = config.settings;

      niriEnvironment =
        let
          toNiriEnv =
            var:
            if isNull var then
              "null"
            else
              "\"${inputs.hjem.hjem-lib.${config.pkgs.stdenv.hostPlatform.system}.toEnv var}\"";
        in
        lib.pipe cfg.extraVariables [
          (lib.mapAttrsToList (n: v: n + " ${toNiriEnv v}"))
          (lib.concatStringsSep "\n")
        ];

      niriConf = lib.concatStringsSep "\n" [
        (lib.optionalString (cfg.extraVariables != { }) ''
          environment {
            ${niriEnvironment}
          }
        '')
        (lib.optionalString (cfg.binds != { }) ''
          binds {
            ${toNiriBinds cfg.binds}
          }
        '')
        (toNiriSpawnAtStartup cfg.spawn-at-startup)
        cfg.config
      ];
      checkedNiriConf = config.pkgs.writeTextFile {
        name = "niri.kdl";
        text = niriConf;
        checkPhase = ''
          ${lib.getExe config.package} validate -c $out
        '';
      };
    in
    {
      options = {
        "config.kdl" = lib.mkOption {
          type = wlib.types.file config.pkgs;
          default.path = checkedNiriConf;
          visible = false;
        };
        settings = mkNiriOptions config.pkgs;
      };

      config.package = lib.mkDefault config.pkgs.niri;
      config.filesToPatch = [
        "share/applications/*.desktop"
        "share/systemd/user/niri.service"
      ];
      config.env = {
        NIRI_CONFIG = toString config."config.kdl".path;
      };
    }
  );

  flake.nixosModules.core =
    { pkgs, ... }:
    {
      options.custom = {
        programs.niri = {
          settings = mkNiriOptions pkgs;
        };
      };
    };
}
