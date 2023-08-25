{
  config,
  lib,
  ...
}: let
  cfg = config.iynaix.shell;
in {
  programs.fish = {
    enable = true;
    functions = lib.mapAttrs (name: value:
      if lib.isString value
      then value
      else value.fishBody)
    cfg.functions;
    shellInit = ''
      set fish_greeting

      ${cfg.initExtra}
    '';
  };
}
