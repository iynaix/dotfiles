{ lib, ... }:
let
  inherit (lib)
    assertMsg
    concatMapStrings
    getExe'
    listToAttrs
    mkEnableOption
    mkIf
    mkOption
    versionOlder
    ;
in
{
  flake.nixosModules.core =
    { self, ... }:
    {
      options.custom = {
        programs = {
          hyprland = {
            plugins = mkOption {
              type = with lib.types; listOf (either package path);
              default = [ ];
              description = ''
                List of Hyprland plugins to use. Can either be packages or
                absolute plugin paths.
              '';
            };
            qtile = mkEnableOption "qtile like behavior for workspaces";
            settings = self.lib.types.hyprlandSettingsType;
          };
          hyprnstack.enable = mkEnableOption "hyprnstack";
        };
      };
    };

  flake.nixosModules.wm =
    {
      config,
      host,
      pkgs,
      self,
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
      hyprlandConfText =
        concatMapStrings (attrs: self.lib.generators.toHyprconf { inherit attrs importantPrefixes; })
          [
            # systemd activation blurb
            {
              exec-once = [
                "${getExe' pkgs.dbus "dbus-update-activation-environment"} --systemd DISPLAY HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP && systemctl --user stop hyprland-session.target && systemctl --user start hyprland-session.target"
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
                map (p: "hyprctl plugin load ${mkEntry p}") config.custom.programs.hyprland.plugins;
            }
            config.custom.programs.hyprland.settings
          ];
    in
    {
      environment = {
        shellAliases = {
          hyprland = "Hyprland";
          hypr-log = "hyprctl rollinglog --follow";
        };

        variables = mkIf (host == "vm" || host == "vm-hyprland") {
          WLR_RENDERER_ALLOW_SOFTWARE = "1";
        };
      };

      xdg.portal = {
        config = {
          hyprland = {
            default = "hyprland";
            "org.freedesktop.impl.portal.FileChooser" = "gtk";
          };
        };
      };

      # use the config file in home as wrapping the package produces as an error
      # when nixos tries to call it
      hj.xdg.config.files."hypr/hyprland.conf".text = hyprlandConfText;

      programs.hyprland = {
        enable =
          assert (
            assertMsg (versionOlder config.programs.hyprland.package.version "0.53") "hyprland updated, sync with hyprnstack?"
          );
          true;
        # package =
        #   assert (assertMsg (versionOlder config.programs.hyprland.package.version "0.42") "hyprland: use version from nixpkgs?");
        #   inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      };

      # hyprland-session systemd service, from home-manager
      systemd.user.targets.hyprland-session = {
        unitConfig = {
          Description = "Hyprland compositor session";
          Documentation = [ "man:systemd.special(7)" ];
          BindsTo = [ "graphical-session.target" ];
          Wants = [
            "graphical-session-pre.target"
          ];
          # ++ optional cfg.systemd.enableXdgAutostart "xdg-desktop-autostart.target";
          After = [ "graphical-session-pre.target" ];
          # Before = lib.mkIf cfg.systemd.enableXdgAutostart [ "xdg-desktop-autostart.target" ];
        };
      };

      # waybar config for hyprland
      custom.programs.waybar.config = {
        "hyprland/workspaces" = {
          format = "{name}";
          persistent-workspaces = listToAttrs (
            map (mon: {
              inherit (mon) name;
              value = mon.workspaces;
            }) config.custom.hardware.monitors
          );
        };
      };

      custom.persist = {
        home.cache.directories = [ ".cache/hyprland" ];
      };
    };
}
