{ config, pkgs, user, lib, host, ... }:

{
  imports = [
    ./hardware.nix
    ../../modules/media/download.nix # torrenting stuff
  ];

  services.xserver.videoDrivers = [ "nvidia" ];

  environment.systemPackages = with pkgs; [ ];

  home-manager.users.${user} = {
    xsession.windowManager.bspwm = {
      monitors = {
        "${host.monitor1}" = [ "1" "2" "3" "4" "5" ];
        "${host.monitor2}" = [ "6" "7" "8" ];
        "${host.monitor3}" = [ "9" "10" ];
      };
      extraConfigEarly = lib.concatStringsSep "\n" [
        ("xrandr --output '${host.monitor1}' --primary --mode 3440x1440 --rate 144 --pos 1440x1080 --rotate normal"
          + " --output '${host.monitor2}' --mode 2560x1440 --pos 0x728 --rotate left"
          + " --output '${host.monitor3}' --mode 1920x1080 --pos 1754x0")
      ];
      extraConfig = lib.concatStringsSep "\n" [
        ("xwallpaper --output '${host.monitor1}' --zoom ~/Pictures/Wallpapers/gits-catppuccin-3440.png"
          + " --output '${host.monitor2}' --zoom ~/Pictures/Wallpapers/gits-catppuccin-2560.png"
          + " --output '${host.monitor3}' --zoom ~/Pictures/Wallpapers/gits-catppuccin-1920.png")
      ];
    };

    services.polybar = {
      script = "polybar primary &; polybar secondary &; polybar tertiary &;";
    };

    home = {
      packages = with pkgs; [
        # additional media players
        smplayer
        vlc
      ];
    };
  };
}
