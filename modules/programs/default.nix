{ pkgs, user, config, ... }: {
  imports = [
    ./alacritty.nix
    ./brave.nix
    ./firefox.nix
    ./keyring.nix
    ./nemo.nix
    ./vscode.nix
    ./zathura.nix
    ../media/mpv.nix
  ];

  config = {
    home-manager.users.${user} = {
      home.packages = with pkgs; [ libreoffice ];
    };

    iynaix.persist.home.directories = [
      ".local/state/wireplumber"
    ];
  };
}
