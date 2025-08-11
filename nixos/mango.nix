{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
in
mkIf (config.hm.custom.wm == "mango") {
  programs = {
    mango = {
      enable = true;
      inherit (config.hm.wayland.windowManager.mango) package;
    };
  };
}
