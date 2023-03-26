{
  pkgs,
  user,
  lib,
  config,
  ...
}: {
  config = {
    home-manager.users.${user} = {
      home.packages = [pkgs.ranger];

      xdg.configFile = {
        "ranger" = {
          source = ./ranger;
          recursive = true;
        };

        "ranger/shortcuts.conf".text = lib.mkAfter (lib.concatStringsSep "\n"
          (lib.mapAttrsToList
            (name: value: (lib.concatStringsSep "\n" [
              "map g${name} cd ${value}"
              "map t${name} tab_new ${value}"
              "map m${name} shell mv -v ${value}"
              "map Y${name} shell cp -rv ${value}"
            ]))
            config.iynaix.shortcuts));
      };
    };
  };
}
