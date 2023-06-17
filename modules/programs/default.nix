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
    ./wezterm.nix
    ./zathura.nix
  ];

  config = {
    home-manager.users.${user} = {
      home.packages = with pkgs; [
        libreoffice
        libnotify
        neofetch
        # nix dev stuff
        nil
        pkgs.alejandra
      ];
    };

    iynaix.persist.home.directories = [
      ".local/state/wireplumber"
    ];
  };
}
