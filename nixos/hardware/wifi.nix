{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.iynaix-nixos.wifi.enable {
    environment.systemPackages = with pkgs; [
      bc # needed for rofi-wifi-menu
      wirelesstools
    ];

    hm = {...} @ hmCfg: {
      # add wifi indicator to waybar
      iynaix.waybar = {
        config = {
          modules-right = lib.mkBefore ["network"];
          network = {
            format = "  {essid}";
            format-disconnected = "󰖪  Offline";
            on-click = "~/.config/rofi/rofi-wifi-menu";
            on-click-right = "${hmCfg.config.iynaix.terminal.exec} nmtui";
            tooltip = false;
          };
        };
      };
    };

    iynaix-nixos.persist = {
      root.directories = [
        "/etc/NetworkManager"
      ];
    };
  };
}
