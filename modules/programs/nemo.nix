{ pkgs, theme, ... }: {
  home = { packages = with pkgs; [ cinnamon.nemo dconf gnome.dconf-editor ]; };

  dconf.settings = {
    "org/nemo/preferences" = {
      default-folder-viewer = "list-view";
      show-hidden-files = true;
      start-with-dual-pane = true;
    };
    "org/nemo/preferences/menu-config" = {
      selection-menu-make-link = true;
      selection-menu-copy-to = true;
      selection-menu-move-to = true;
    };
  };
}
