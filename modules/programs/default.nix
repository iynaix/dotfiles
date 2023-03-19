{ pkgs, user, config, ... }: {
  imports = [
    ./brave.nix
    ./firefox.nix
    ./helix.nix
    ./keyring.nix
    ./kitty.nix
    ./nemo.nix
    ./neovim.nix
    ./pywal.nix
    ./rofi.nix
    ./vscode.nix
    ./zathura.nix
  ];

  config = {
    xdg.mime.defaultApplications = {
      "image/jpeg" = "imv-dir.desktop";
      "image/png" = "imv-dir.desktop";
    };

    home-manager.users.${user} = {
      home.packages = with pkgs; [
        imv
        libreoffice
      ];
    };

    iynaix.persist.home.directories = [
      ".local/state/wireplumber"
    ];
  };
}
