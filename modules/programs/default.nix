{ pkgs, ... }: {
  imports = [ ./alacritty.nix ./mpv.nix ];

  home = {
    packages = with pkgs; [
      clipmenu
      clipnotify
      firefox-devedition-bin
      libreoffice
    ];
  };
}
