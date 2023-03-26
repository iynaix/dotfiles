{
  pkgs,
  user,
  system,
  inputs,
  ...
}: {
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
    ./wezterm.nix
    ./zathura.nix
  ];

  config = {
    home-manager.users.${user} = {
      home.packages = with pkgs; [
        gparted
        libreoffice
        libnotify
        # nix dev stuff
        nil
        inputs.alejandra.defaultPackage.${system}
      ];
    };

    iynaix.persist.home.directories = [
      ".local/state/wireplumber"
    ];
  };
}
