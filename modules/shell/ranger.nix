{ pkgs, user, lib, config, ... }: {
  config = {
    home-manager.users.${user} = {
      home = {
        packages = with pkgs; [ ranger ];

        file.".config/ranger" = {
          source = ./ranger;
          recursive = true;
        };

        #
        file.".config/ranger/shortcuts.conf".text = lib.mkAfter (lib.concatStringsSep "\n"
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
