{
  lib,
  pkgs,
  ...
}: {
  programs.vscode = {
    enable = true;
    # lock vscode to 1.81.1 because native titlebar causes vscode to crash
    # https://github.com/microsoft/vscode/issues/184124#issuecomment-1717959995
    package = assert (lib.assertMsg (lib.hasPrefix "1.85" pkgs.vscode.version) "vscode: has wayland crash been fixed?");
      pkgs.vscode.overrideAttrs (o: let
        version = "1.81.1";
        plat = "linux-x64";
      in {
        src = pkgs.fetchurl {
          name = "VSCode_${version}_${plat}.tar.gz";
          url = "https://update.code.visualstudio.com/${version}/${plat}/stable";
          sha256 = "sha256-Tqawqu0iR0An3CZ4x3RGG0vD3x/PvQyRhVThc6SvdEg=";
        };
        # preFixup = ''
        #   gappsWrapperArgs+=(
        #     # Add gio to PATH so that moving files to the trash works when not using a desktop environment
        #     --prefix PATH : ${pkgs.glib.bin}/bin
        #     --add-flags "''${NIXOS_OZONE_WL:+''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"
        #     --add-flags ${lib.escapeShellArg commandLineArgs}
        #   )
        # '';
      });
  };

  # add password-store: gnome for keyring to work
  # https://github.com/microsoft/vscode/issues/187338
  home.file.".vscode/argv.json" = {
    force = true;
    text = ''
      {
      	// "disable-hardware-acceleration": true,
      	"enable-crash-reporter": true,
      	// Unique id used for correlating crash reports sent from this instance.
      	// Do not edit this value.
      	"crash-reporter-id": "2e9e4d50-af3a-4bd9-9dfb-7ded6d285cc8",
        "password-store": "gnome"
      }
    '';
  };

  custom.persist = {
    home.directories = [
      ".console-ninja"
      ".config/Code"
      ".vscode"
    ];
  };
}
