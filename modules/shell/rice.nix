{ inputs, ... }:
{
  flake.nixosModules.core =
    { pkgs, ... }:
    {
      environment = {
        systemPackages = with pkgs; [
          asciiquarium
          cbonsai
          cmatrix
          fastfetch
          nitch
          pipes-rs
          scope-tui
          tenki
          terminal-colors
          inputs.wfetch.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];

        shellAliases = {
          neofetch = "fastfetch --config neofetch";
          wwfetch = "wfetch --wallpaper";
        };
      };
    };

  flake.nixosModules.gui =
    { config, pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.imagemagick
      ];

      custom.programs = {
        noctalia.colors.templates = {
          wfetch = {
            # dummy values so noctalia doesn't complain
            input_path = "${config.hj.xdg.config.directory}/user-dirs.conf";
            output_path = "/dev/null";
            post_hook = "bash -c 'pgrep -f .wfetch-wrapped >/dev/null && pkill -SIGUSR2 .wfetch-wrapped || true'";
          };
        };
      };
    };
}
