{ pkgs, user, config, ... }: {
  imports = [
    ./alacritty.nix
    ./brave.nix
    ./firefox.nix
    ./keyring.nix
    ./nemo.nix
    ./vscode.nix
    ./zathura.nix
    ../media
  ];

  config = {
    home-manager.users.${user} = {
      home.packages = with pkgs; [ gparted libreoffice ];
    };

    iynaix.persist.home.directories = [
      ".local/state/wireplumber"
    ];
  };
}
