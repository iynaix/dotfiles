{
  pkgs,
  user,
  ...
}: {
  config = {
    iynaix.hyprland.extraBinds.exec-once = [
      "${pkgs.xorg.xhost}/bin/xhost +local:"
    ];

    home-manager.users.${user} = {
      home.packages = with pkgs; [gparted];
    };
  };
}
