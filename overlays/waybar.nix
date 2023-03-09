self: super: {
  waybar = super.waybar.overrideAttrs (oldAttrs: {
    # extra fixes, adapated from:
    # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=waybar-hyprland-git

    # use hyprctl to switch workspaces
    postPatch = ''
      sed -i 's/zext_workspace_handle_v1_activate(workspace_handle_);/const std::string command = "hyprctl dispatch workspace " + name_;\n\tsystem(command.c_str());/g' src/modules/wlr/workspace_manager.cpp
    '';

    mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
  });
}
