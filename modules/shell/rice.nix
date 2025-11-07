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
          (inputs.wfetch.packages.${pkgs.stdenv.hostPlatform.system}.default.override { iynaixos = true; })
        ];

        shellAliases = {
          neofetch = "fastfetch --config neofetch";
          wwfetch = "wfetch --wallpaper";
        };
      };
    };

  flake.nixosModules.gui =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.imagemagick
      ];
    };
}
