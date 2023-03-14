{ pkgs, host, user, lib, config, ... }:
let
  cfg = config.iynaix.kmonad;
in
{
  options.iynaix.kmonad = {
    enable = lib.mkEnableOption "kmonad";
  };

  config = { };
}
