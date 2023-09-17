{
  inputs,
  pkgs,
  ...
}: {
  programs.vscode = {
    enable = true;
    # lock vscode to 1.81.1 because native titlebar causes vscode to crash
    # https://github.com/microsoft/vscode/issues/184124#issuecomment-1717959995
    package =
      (import inputs.nixpkgs-vscode {
        system = pkgs.system;
        config.allowUnfree = true;
      })
      .vscode;
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

  iynaix.persist = {
    home.directories = [
      ".console-ninja"
      ".config/Code"
      ".vscode"
    ];
  };
}
