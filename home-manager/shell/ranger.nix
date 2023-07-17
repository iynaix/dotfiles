{
  pkgs,
  lib,
  config,
  ...
}: {
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
        config.iynaix.shortcuts
        ++ [
          # set preview images method here
          ''set preview_images_method ${
              if config.iynaix.terminal.package.pname == "kitty"
              then "kitty"
              else "iterm2"
            }''
        ]));
  };
}