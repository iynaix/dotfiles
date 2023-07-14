{
  pkgs,
  user,
  ...
}: {
  imports = [
    ./cava.nix
    ./neofetch.nix
  ];

  config = {
    home-manager.users.${user} = {
      home.packages = with pkgs; [
        neofetch
        nitch
        pipes
        cmatrix
        # cbonsai
      ];
    };
  };
}
