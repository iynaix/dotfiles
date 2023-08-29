{lib, ...}: {
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "TTY";
      theme_background = false;
      cpu_single_graph = true;
      show_disks = false;
      use_fstab = true;
    };
  };

  xdg.configFile."btop/themes/catppuccin-mocha.theme".text = lib.concatStringsSep "\n" (lib.mapAttrsToList (key: value: ''theme[${key}]="${value}"'') {
    main_bg = "#1E1E2E";
    main_fg = "#CDD6F4";
    title = "#CDD6F4";
    hi_fg = "#89B4FA";
    selected_bg = "#45475A";
    selected_fg = "#89B4FA";
    inactive_fg = "#7F849C";
    graph_text = "#F5E0DC";
    meter_bg = "#45475A";
    proc_misc = "#F5E0DC";
    cpu_box = "#74C7EC";
    mem_box = "#A6E3A1";
    net_box = "#CBA6F7";
    proc_box = "#F2CDCD";
    div_line = "#6C7086";
    temp_start = "#F9E2AF";
    temp_mid = "#FAB387";
    temp_end = "#F38BA8";
    cpu_start = "#74C7EC";
    cpu_mid = "#89DCEB";
    cpu_end = "#94E2D5";
    free_start = "#94E2D5";
    free_mid = "#94E2D5";
    free_end = "#A6E3A1";
    cached_start = "#F5C2E7";
    cached_mid = "#F5C2E7";
    cached_end = "#CBA6F7";
    available_start = "#F5E0DC";
    available_mid = "#F2CDCD";
    available_end = "#F2CDCD";
    used_start = "#FAB387";
    used_mid = "#FAB387";
    used_end = "#F38BA8";
    download_start = "#B4BEFE";
    download_mid = "#B4BEFE";
    download_end = "#CBA6F7";
    upload_start = "#B4BEFE";
    upload_mid = "#B4BEFE";
    upload_end = "#CBA6F7";
    process_start = "#74C7EC";
    process_mid = "#89DCEB";
    process_end = "#94E2D5";
  });
}
