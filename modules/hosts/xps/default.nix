topLevel: {
  flake.modules.nixos.host-xps =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) getExe mkIf;
    in
    {
      imports = with topLevel.config.flake.modules.nixos; [
        gui
      ];

      custom = {
        hardware = {
          monitors = [
            {
              name = "eDP-1";
              width = 1920;
              height = 1080;
              workspaces = [
                1
                2
                3
                4
                5
                6
                7
                8
                9
                10
              ];
              refreshRate = if config.custom.wm == "hyprland" then "60" else "59.934";
            }
          ];
        };
        programs = {
          btop.settings = {
            custom_gpu_name0 = "Intel HD Graphics 5500";
          };
        };
        persist = {
          home.directories = [ "Downloads" ];
        };
      };

      networking.hostId = "17521d0b"; # required for zfs

      # larger runtime directory size to not run out of ram while building
      # https://discourse.nixos.org/t/run-usr-id-is-too-small/4842
      services.logind.extraConfig = "RuntimeDirectorySize=3G";

      # touchpad support
      services.libinput.enable = true;

      security.wrappers = mkIf config.custom.programs.btop.enable {
        btop = {
          capabilities = "cap_perfmon=+ep";
          group = "wheel";
          owner = "root";
          permissions = "0750";
          source = getExe pkgs.btop;
        };
      };
    };
}
