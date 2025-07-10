{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkIf
    ;
in
mkIf (config.custom.wm == "niri") {
  custom = {
    autologinCommand = "niri-session";
  };

  programs.niri.settings = {
    # spawn-at-startup = map (
    #   prog:
    #   if builtins.isString prog then
    #     prog
    #   else
    #     let
    #       inherit (prog) exec packages workspace;
    #       rules = optionalString (workspace != null) "[workspace ${toString workspace} silent]";
    #       finalExec = if exec == null then concatMapStringsSep "\n" getExe packages else exec;
    #     in
    #     "${rules} uwsm app -- ${finalExec}"
    # ) config.custom.startup;
  };
}
