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
    ./nixlang.nix
    ./rice
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
        wallust
      ];
    };

    iynaix.persist.home.directories = [
      ".local/state/wireplumber"
    ];
  };
}
