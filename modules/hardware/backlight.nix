{ pkgs, lib, host, user, config, ... }:
let cfg = config.iynaix.backlight; in
{
  options.iynaix.backlight = {
    enable = lib.mkEnableOption "backlight";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.brightnessctl ];

    home-manager.users.${user} = {
      services = {
        sxhkd.keybindings =
          let
            brightness-change = pkgs.writeShellScriptBin "brightness-change" /* sh */ ''
              # arbitrary but unique message id
              msgId="906882"

              brightnessctl "$@"

              # query xbacklight for the current brightness
              pct=$(brightnessctl i | grep -i current | cut -d' ' -f 4 | tr -dc '0-9')

              # show backlight notification
              dunstify -a "brightness-change" -u low -r "$msgId" "Backlight: ''${pct}%"
            '';
          in
          {
            "XF86MonBrightnessDown" = "${brightness-change}/bin/brightness-change set 5%-";
            "XF86MonBrightnessUp" = "${brightness-change}/bin/brightness-change set +5%";
          };
      };
    };
  };
}
