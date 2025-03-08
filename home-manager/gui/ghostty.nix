{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    assertMsg
    getExe
    mkEnableOption
    mkIf
    versionOlder
    ;
  cfg = config.custom.ghostty;
  isGhosttyDefault = config.custom.terminal.package == config.programs.ghostty.package;
  inherit (config.custom) terminal;
  # large mouse cursor in gtk4, fixed in gtk 4.17, see:
  # https://github.com/ghostty-org/ghostty/discussions/3167
  ghostty-gtk-cursor-fix = pkgs.ghostty.override {
    wrapGAppsHook4 = pkgs.wrapGAppsNoGuiHook.override {
      isGraphical = true;
      gtk3 =
        (pkgs.__splicedPackages.gtk4.override {
          wayland-protocols = pkgs.wayland-protocols.overrideAttrs (o: rec {
            version = "1.41";
            src = pkgs.fetchurl {
              url = "https://gitlab.freedesktop.org/wayland/${o.pname}/-/releases/${version}/downloads/${o.pname}-${version}.tar.xz";
              hash = "sha256-J4a2sbeZZeMT8sKJwSB1ue1wDUGESBDFGv2hDuMpV2s=";
            };
          });
        }).overrideAttrs
          (o: rec {
            version = "4.17.6";
            src = pkgs.fetchurl {
              url = "mirror://gnome/sources/gtk/${lib.versions.majorMinor version}/gtk-${version}.tar.xz";
              hash = "sha256-366boSY/hK+oOklNsu0UxzksZ4QLZzC/om63n94eE6E=";
            };
            postFixup = ''
              demos=(gtk4-demo gtk4-demo-application gtk4-widget-factory)

              for program in ''${demos[@]}; do
                wrapProgram $dev/bin/$program \
                  --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH:$out/share/gsettings-schemas/${o.pname}-${version}"
              done

              # Cannot be in postInstall, otherwise _multioutDocs hook in preFixup will move right back.
              moveToOutput "share/doc" "$devdoc"
            '';
          });
    };
  };
in
{
  options.custom = {
    ghostty = {
      enable = mkEnableOption "ghostty" // {
        default = true;
      };
    };
  };

  config = mkIf cfg.enable {
    custom.terminal = {
      desktop = "com.mitchellh.ghostty.desktop";
      exec = mkIf isGhosttyDefault "${getExe config.programs.ghostty.package} -e";
    };

    programs.ghostty = {
      enable = true;
      package =
        assert (
          assertMsg (versionOlder pkgs.wayland-protocols.version "1.41") "wayland-protocols updated, update ghostty override"
        );
        assert (assertMsg (versionOlder pkgs.gtk4.version "4.17") "gtk4 updated, remove ghostty override");
        ghostty-gtk-cursor-fix;
      enableBashIntegration = true;
      enableFishIntegration = true;
      settings = {
        background-opacity = terminal.opacity;
        confirm-close-surface = false;
        copy-on-select = "clipboard";
        # disable clipboard copy notifications temporarily until fixed upstream
        # https://github.com/ghostty-org/ghostty/issues/4800#issuecomment-2685774252
        app-notifications = "no-clipboard-copy";
        cursor-style = "bar";
        font-family = terminal.font;
        font-feature = "zero";
        font-size = terminal.size;
        font-style = "Medium";
        minimum-contrast = 1.1;
        window-decoration = false;
        window-padding-x = terminal.padding;
        window-padding-y = terminal.padding;
      };
    };
  };
}
