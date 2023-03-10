{ pkgs, user, lib, config, host, ... }:
let cfg = config.iynaix.pathofbuilding; in
{
  options.iynaix.pathofbuilding = {
    enable = lib.mkEnableOption "pathofbuilding" // { default = true; };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${user} = {
      home.packages = [ (pkgs.callPackage ../../pkgs/pathofbuilding { }) ];
    };
  };
}
