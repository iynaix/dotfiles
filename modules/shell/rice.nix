{
  flake.nixosModules.core =
    { inputs, pkgs, ... }:
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
        matugen.settings.templates = {
          wfetch = {
            # dummy value so matugen doesn't complain
            input_path = "${config.hj.xdg.config.directory}/user-dirs.conf";
            post_hook = "bash -c 'pgrep -f .wfetch-wrapped >/dev/null && pkill -SIGUSR2 .wfetch-wrapped || true'";
          };
        };
      };
    };
}
