{ inputs, lib, ... }:
let
  # copied from home-manager:
  # https://github.com/nix-community/home-manager/blob/master/modules/lib/generators.nix
  toHyprconf =
    {
      attrs,
      indentLevel ? 0,
      importantPrefixes ? [ "$" ],
    }:
    let
      initialIndent = lib.concatStrings (lib.replicate indentLevel "  ");

      toHyprconf' =
        indent: attrs:
        let
          sections = lib.filterAttrs (_n: v: lib.isAttrs v || (lib.isList v && lib.all lib.isAttrs v)) attrs;

          mkSection =
            n: attrs:
            if lib.isList attrs then
              (lib.concatMapStringsSep "\n" (a: mkSection n a) attrs)
            else
              ''
                ${indent}${n} {
                ${toHyprconf' "  ${indent}" attrs}${indent}}
              '';

          mkFields = lib.generators.toKeyValue {
            listsAsDuplicateKeys = true;
            inherit indent;
          };

          allFields = lib.filterAttrs (
            _n: v: !(lib.isAttrs v || (lib.isList v && lib.all lib.isAttrs v))
          ) attrs;

          isImportantField =
            n: _: lib.foldl (acc: prev: if lib.hasPrefix prev n then true else acc) false importantPrefixes;

          importantFields = lib.filterAttrs isImportantField allFields;

          fields = removeAttrs allFields (lib.mapAttrsToList (n: _: n) importantFields);
        in
        mkFields importantFields
        + lib.concatStringsSep "\n" (lib.mapAttrsToList mkSection sections)
        + mkFields fields;
    in
    toHyprconf' initialIndent attrs;

  # hyprland settings type, copied from home-manager:
  # https://github.com/nix-community/home-manager/blob/master/modules/services/window-managers/hyprland.nix
  hyprlandSettingsType = lib.mkOption {
    type =
      with lib.types;
      let
        valueType =
          nullOr (oneOf [
            bool
            int
            float
            str
            path
            (attrsOf valueType)
            (listOf valueType)
          ])
          // {
            description = "Hyprland configuration value";
          };
      in
      valueType;
    default = { };
    description = ''
      Hyprland configuration written in Nix. Entries with the same key
      should be written as lists. Variables' and colors' names should be
      quoted. See <https://wiki.hypr.land> for more examples.
    '';
    example = lib.literalExpression ''
      {
        decoration = {
          shadow_offset = "0 5";
          "col.shadow" = "rgba(00000099)";
        };

        "$mod" = "SUPER";

        bindm = [
          # mouse movements
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
          "$mod ALT, mouse:272, resizewindow"
        ];
      }
    '';
  };
  hyprlandOptions = {
    plugins = lib.mkOption {
      type = with lib.types; listOf (either package path);
      default = [ ];
      description = ''
        List of Hyprland plugins to use. Can either be packages or
        absolute plugin paths.
      '';
    };
    qtile = lib.mkEnableOption "qtile like behavior for workspaces";
    settings = hyprlandSettingsType;
  };
in
{
  flake.libCustom = {
    generators = {
      inherit toHyprconf;
    };
    types = {
      inherit hyprlandSettingsType;
    };
  };

  flake.wrapperModules.hyprland = inputs.wrappers.lib.wrapModule (
    {
      config,
      wlib,
      ...
    }:
    let
      importantPrefixes = [
        "$"
        "bezier"
        "name"
        "output"
      ];
      # don't use lib.mkMerge as the order is important
      hyprlandConfText = lib.concatMapStrings (attrs: toHyprconf { inherit attrs importantPrefixes; }) [
        # systemd activation blurb
        {
          exec-once = [
            "${lib.getExe' config.pkgs.dbus "dbus-update-activation-environment"} --systemd DISPLAY HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP && systemctl --user restart hyprland-session.target"
          ];
        }
        # handle the plugins, loaded before the settings, implementation from home-manager:
        # https://github.com/nix-community/home-manager/blob/master/modules/services/window-managers/hyprland.nix
        {
          "exec-once" =
            let
              mkEntry =
                entry: if lib.types.package.check entry then "${entry}/lib/lib${entry.pname}.so" else entry;
            in
            map (p: "hyprctl plugin load ${mkEntry p}") config.plugins;
        }
        config.settings
        # source the hyprland config at the default location
        { source = "~/.config/hypr/hyprland.conf"; }
      ];
      checkedHyprlandConf = config.pkgs.writeTextFile {
        name = "checked-hyprland.conf";
        text = hyprlandConfText;
        # validate hyprland config, filter out source to non-existent file
        # can be removed when the PR is merged:
        # https://github.com/hyprwm/Hyprland/pull/12286
        checkPhase = ''
          export XDG_RUNTIME_DIR=$(mktemp -d)
          grep -v '^source' "$out" > config_without_source.conf
          ${lib.getExe config.package} --verify-config -c config_without_source.conf
        '';
      };
    in
    {
      options = hyprlandOptions // {
        "hyprland.conf" = lib.mkOption {
          type = wlib.types.file config.pkgs;
          default.path = checkedHyprlandConf;
          visible = false;
        };
      };

      config.package = lib.mkDefault config.pkgs;
      config.filesToPatch = [
        "share/wayland-sessions/*.desktop"
      ];
      config.flags = {
        "--config" = toString config."hyprland.conf".path;
      };
    }
  );

  flake.nixosModules.core = {
    options.custom = {
      programs = {
        hyprland = hyprlandOptions;
        hyprnstack.enable = lib.mkEnableOption "hyprnstack";
      };
    };
  };
}
