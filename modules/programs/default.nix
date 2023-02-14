{ pkgs, ... }: {
  imports = [ ./alacritty.nix ../media/mpv.nix ];

  home = { packages = with pkgs; [ libreoffice ]; };

  programs = {
    # firefox dev edition
    firefox = {
      enable = true;
      package = pkgs.firefox-devedition-bin;
    };
  };
}
