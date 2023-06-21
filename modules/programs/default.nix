{
  pkgs,
  user,
  ...
}: {
  imports = [
    ./brave.nix
    ./firefox.nix
    ./gparted.nix
    # ./helix.nix
    ./pathofbuilding
    ./imv.nix
    ./keyring.nix
    ./kitty.nix
    ./nemo.nix
    ./neovim.nix
    ./pywal.nix
    ./rofi.nix
    ./virt-manager.nix
    ./vscode.nix
    ./wallust.nix
    ./wezterm.nix
    ./zathura.nix
  ];

  config = {
    home-manager.users.${user} = {
      home.packages = with pkgs; [
        libreoffice
        libnotify
        neofetch
        wallust
        # nix dev stuff
        nil
        alejandra
      ];
    };

    iynaix.persist.home.directories = [
      ".local/state/wireplumber"
    ];
  };
}
