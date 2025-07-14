_: {
  specialisation = {
    # boot into a tty without a DE / WM
    tty.configuration = {
      hm.custom = {
        currentSpecialisation = "tty";
        wm = "tty";
      };
    };

    niri.configuration = {
      hm.custom = {
        currentSpecialisation = "niri";
        wm = "niri";
      };
    };

    hyprland.configuration = {
      hm.custom = {
        currentSpecialisation = "hyprland";
        wm = "hyprland";
      };
    };
  };
}
