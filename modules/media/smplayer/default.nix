{
  pkgs,
  user,
  config,
  lib,
  ...
}: {
  options.iynaix.smplayer = {
    enable = lib.mkEnableOption "smplayer";
  };

  config = lib.mkIf config.iynaix.smplayer.enable {
    home-manager.users.${user} = {
      xdg.configFile."smplayer/themes" = {
        source = ./themes;
        recursive = true;
      };

      home.packages = [pkgs.smplayer];
    };

    nixpkgs.overlays = [
      (self: super: {
        # patch smplayer to not open an extra window under wayland
        # https://github.com/smplayer-dev/smplayer/issues/369#issuecomment-1519941318
        smplayer = super.smplayer.overrideAttrs (oldAttrs: {
          patches = [
            ./smplayer-shared-memory.patch
          ];
        });

        mpv = super.mpv-unwrapped.overrideAttrs (oldAttrs: {
          patches = [
            ./mpv-meson.patch
            ./mpv-mod.patch
          ];
        });
      })
    ];
  };
}
