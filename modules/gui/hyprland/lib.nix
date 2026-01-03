{ inputs, lib, ... }:
let
  inherit (lib)
    all
    concatMapStrings
    concatMapStringsSep
    concatStrings
    concatStringsSep
    filterAttrs
    foldl
    generators
    getExe'
    hasPrefix
    isAttrs
    isList
    mapAttrsToList
    mkDefault
    mkEnableOption
    mkOption
    replicate
    ;
  # copied from home-manager:
  # https://github.com/nix-community/home-manager/blob/master/modules/lib/generators.nix
  toHyprconf =
    {
      attrs,
      indentLevel ? 0,
      importantPrefixes ? [ "$" ],
    }:
    let
      initialIndent = concatStrings (replicate indentLevel "  ");

      toHyprconf' =
        indent: attrs:
        let
          sections = filterAttrs (_n: v: isAttrs v || (isList v && all isAttrs v)) attrs;

          mkSection =
            n: attrs:
            if lib.isList attrs then
              (concatMapStringsSep "\n" (a: mkSection n a) attrs)
            else
              ''
                ${indent}${n} {
                ${toHyprconf' "  ${indent}" attrs}${indent}}
              '';

          mkFields = generators.toKeyValue {
            listsAsDuplicateKeys = true;
            inherit indent;
          };

          allFields = filterAttrs (_n: v: !(isAttrs v || (isList v && all isAttrs v))) attrs;

          isImportantField =
            n: _: foldl (acc: prev: if hasPrefix prev n then true else acc) false importantPrefixes;

          importantFields = filterAttrs isImportantField allFields;

          fields = removeAttrs allFields (mapAttrsToList (n: _: n) importantFields);
        in
        mkFields importantFields
        + concatStringsSep "\n" (mapAttrsToList mkSection sections)
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
    plugins = mkOption {
      type = with lib.types; listOf (either package path);
      default = [ ];
      description = ''
        List of Hyprland plugins to use. Can either be packages or
        absolute plugin paths.
      '';
    };
    qtile = mkEnableOption "qtile like behavior for workspaces";
    settings = hyprlandSettingsType;
  };
in
{
  flake.lib = {
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
      # don't use mkMerge as the order is important
      hyprlandConfText = concatMapStrings (attrs: toHyprconf { inherit attrs importantPrefixes; }) [
        # systemd activation blurb
        {
          exec-once = [
            "${getExe' config.pkgs.dbus "dbus-update-activation-environment"} --systemd DISPLAY HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP && systemctl --user restart hyprland-session.target"
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
      ];
    in
    {
      options = hyprlandOptions // {
        "hyprland.conf" = mkOption {
          type = wlib.types.file config.pkgs;
          default.content = hyprlandConfText;
          visible = false;
        };
      };

      config.package = mkDefault config.pkgs;
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
        hyprnstack.enable = mkEnableOption "hyprnstack";
      };
    };
  };
}
