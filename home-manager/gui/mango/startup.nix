{ config, lib, ... }:
let
  inherit (lib) mkIf;
in
mkIf (config.custom.wm == "mango") {
  custom = {
    autologinCommand = "mango -d &> /tmp/mango.log";
  };
}
