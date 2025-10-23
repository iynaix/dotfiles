{
  flake.nixosModules.wm =
    { config, lib, ... }:
    let
      inherit (lib) mkIf;
    in
    {
      # autologinCommand = "mango";
      custom.autologinCommand = mkIf (config.custom.wm == "mango") "mango -d &> /tmp/mango.log";
    };
}
