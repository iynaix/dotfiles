{ config, lib, ... }:
let
  inherit (lib) mkIf;
in
mkIf (config.custom.wm == "mango") {
  hm.custom = {
    # autologinCommand = "mango";
    autologinCommand = "mango -d &> /tmp/mango.log";
  };
}
