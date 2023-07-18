{
  user,
  lib,
  config,
  ...
}: let
  cfg = config.iynaix.docker;
in {
  config = lib.mkIf cfg.enable {
    users.users.${user}.extraGroups = ["docker"];

    virtualisation.docker.enable = true;
  };
}
