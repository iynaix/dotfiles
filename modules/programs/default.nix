{ pkgs, user, ... }: {
  imports = [ ./alacritty.nix ./keyring.nix ./nemo.nix ./zathura.nix ../media/mpv.nix ];

  home-manager.users.${user} = {
    home = { packages = with pkgs; [ libreoffice ]; };

    programs = {
      # firefox dev edition
      firefox = {
        enable = true;
        package = pkgs.firefox-devedition-bin;
      };
    };
  };
}
