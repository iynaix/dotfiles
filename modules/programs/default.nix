{ pkgs, user, config, ... }: {
  imports = [
    ./brave.nix
    ./firefox.nix
    ./helix.nix
    ./imv.nix
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

    home-manager.users.${user} = {
      home.packages = with pkgs; [
        gparted
        libreoffice
      ];
    };

    iynaix.persist.home.directories = [
      ".local/state/wireplumber"
    ];
  };
}
