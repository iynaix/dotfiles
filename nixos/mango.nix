{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  programs.mango = mkIf (config.hm.custom.wm == "mango") {
    enable = true;
  };
}
