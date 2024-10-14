{
  config,
  inputs,
  pkgs,
  ...
}:
{
  home = {
    packages =
      with pkgs;
      [
        asciiquarium
        cbonsai
        cmatrix
        fastfetch
        nitch
        pipes-rs
        scope-tui
        tenki
      ]
      ++ lib.optionals (!config.custom.headless) [
        imagemagick
      ];

    shellAliases = {
      neofetch = "fastfetch --config neofetch";
      wwfetch = "wfetch --wallpaper";
    };
  };

  custom.shell.packages = {
    wfetch =
      # automatically handle display scaling for wfetch
      if config.custom.hyprland.enable then
        {
          runtimeInputs = [
            pkgs.jq
            config.wayland.windowManager.hyprland.package
            inputs.wfetch.packages.${pkgs.system}.wfetch
          ];
          text = ''
            scale=$(hyprctl monitors -j | jq -r 'map(select(.focused == true)) | .[0].scale')
            wfetch --scale "$scale" "$@"
          '';
        }
      else
        inputs.wfetch.packages.${pkgs.system}.wfetch;
  };

  # create xresources
  xresources = {
    path = "${config.xdg.configHome}/.Xresources";
    properties = {
      "Xft.dpi" = 96;
      "Xft.antialias" = true;
      "Xft.hinting" = true;
      "Xft.rgba" = "rgb";
      "Xft.autohint" = false;
      "Xft.hintstyle" = "hintslight";
      "Xft.lcdfilter" = "lcddefault";

      "*.font" = "JetBrainsMono Nerd Font Mono:Medium:size=12";
      "*.bold_font" = "JetBrainsMono Nerd Font Mono:Bold:size=12";
    };
  };
}
