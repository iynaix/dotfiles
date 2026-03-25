{ lib, ... }:
{
  flake.modules.nixos.core =
    { config, pkgs, ... }:
    {
      options.custom = {
        programs.print-config = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = "Attrs of program and the command to print their config.";
        };
      };

      config =
        let
          config-list = pkgs.writeShellApplication {
            name = "config-list";
            text = /* sh */ ''
              sort -ui <<< "${lib.concatLines (lib.attrNames config.custom.programs.print-config)}"
            '';
          };
        in
        {
          environment.systemPackages = [
            config-list
          ]
          # add a `PROGRAM-config` command for each program
          ++ (lib.mapAttrsToList (
            prog: cmd:
            pkgs.writeShellApplication {
              name = "${prog}-config";
              runtimeInputs = [ pkgs.moor ];
              text = cmd;
            }
          ) config.custom.programs.print-config);
        };
    };
}
