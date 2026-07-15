{
  inputs,
  lib,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    {
      packages = rec {
        eza = inputs.wrappers.lib.wrapPackage {
          inherit pkgs;
          package = pkgs.eza;
          flags = {
            "--icons" = true;
            "--group-directories-first" = true;
            "--header" = true;
            "--octal-permissions" = true;
            "--no-permissions" = true;
            "--hyperlink" = true;
          };
          passthru = {
            shellAliases = {
              cls = "command ls";
              ls = "eza";
              ll = "eza -l";
              la = "eza -a";
              lt = "eza --tree";
              lla = "eza -la";
            };
          };
        };
        eza-tree = pkgs.writeShellApplication {
          name = "tree";
          runtimeInputs = [ eza ];
          text = /* sh */ ''
            # Get all arguments except the last one
            args=("''${@:1:$#-1}")

            # Get the last argument
            last_arg="''${!#}"

            if [ -L "$last_arg" ]; then
                set -- "''${args[@]}" "$(readlink -f "$last_arg")"
            else
                # If it's not a symlink, keep the original arguments
                set -- "$@"
            fi

            # run eza with resolved arguments
            eza -la --git-ignore --tree --hyperlink --level 5 "$@"
          '';
        };
      };
    };

  flake.modules.nixos.core =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [
        (_: _prev: {
          eza = pkgs.custom.eza;
        })
      ];

      environment = {
        shellAliases = {
          t = "tree";
        };
      };

      custom.programs.print-config = {
        eza = /* sh */ ''moor --lang sh "${lib.getExe pkgs.eza}"'';
      };
    };
}
