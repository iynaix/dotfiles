{
  pkgs,
  user,
  ...
}: {
  imports = [
    ./brave.nix
    ./docker.nix
    ./firefox.nix
    ./gparted.nix
    # ./helix.nix
    ./imv.nix
    ./keyring.nix
    ./nemo.nix
    ./nixlang.nix
    ./overlays.nix
    ./virt-manager.nix
    ./vscode.nix
    ./zathura.nix
  ];

  config = {
    home-manager.users.${user} = {
      home.packages = with pkgs; [
        libreoffice
        libnotify
      ];
    };

    iynaix.persist.home.directories = [
      ".local/state/wireplumber"
    ];
  };
}
