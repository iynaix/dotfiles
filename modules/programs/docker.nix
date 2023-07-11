{
  user,
  lib,
  config,
  ...
}: let
  cfg = config.iynaix.docker;
in {
  options.iynaix.docker = {
    enable = lib.mkEnableOption "docker";
  };

  config = lib.mkIf cfg.enable {
    users.users.${user}.extraGroups = ["docker"];

    virtualisation.docker.enable = true;
  };
}
