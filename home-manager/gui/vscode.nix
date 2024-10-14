{ config, lib, ... }:
lib.mkIf (!config.custom.headless) {
  programs.vscode.enable = true;

  home = {
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

    # add password-store: gnome for keyring to work
    # https://github.com/microsoft/vscode/issues/187338
    file.".vscode/argv.json" = {
      force = true;
      text = ''
        {
        	// "disable-hardware-acceleration": true,
        	"enable-crash-reporter": true,
        	// Unique id used for correlating crash reports sent from this instance.
        	// Do not edit this value.
        	"crash-reporter-id": "2e9e4d50-af3a-4bd9-9dfb-7ded6d285cc8",
          "password-store": "gnome-libsecret"
        }
      '';
    };
  };

  custom.persist = {
    home.directories = [
      ".config/Code"
      ".vscode"
    ];
  };
}
