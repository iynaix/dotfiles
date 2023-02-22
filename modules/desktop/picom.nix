{ pkgs, user, lib, config, host, ... }: {
  home-manager.users.${user} = {
    services.picom = {
      enable = true;
      shadow = false;
      fadeDelta = 4;
      inactiveOpacity = 1;
      opacityRules = [
        "100:name *= 'NVIM' && focused"
        "100:window_type = 'popup_menu'"
        # "95:name *= 'NVIM'"
        "90:class_g = 'Alacritty'"
        # "70:class_g = 'Bspwm' && class_i = 'presel_feedback'"
      ];
      backend = "glx";
      settings = {
        blur-method = "dual_kawase";
        blur-size = 12;
        blur-strength = 10;
        invert-color-include = [ "class_g = 'MongoDB Compass'" ];
        glx-no-stencil = true;
      };
    };
  };
}
