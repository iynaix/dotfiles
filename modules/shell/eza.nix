{
  packages =
    { inputs, pkgs, ... }:
    # not using eza wrapper module as it only supports theme, not flags
    {
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
      tree = pkgs.writeShellApplication {
        name = "tree";
        runtimeInputs = [ pkgs.eza ];
        text = /* sh */ ''
          if [ "$#" -eq 0 ]; then
            set -- .
          else
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
          fi

          # run eza with resolved arguments
          eza -a --git-ignore --tree --hyperlink --level 5 "$@"
        '';
      };
    };

  config =
    { lib, pkgs, ... }:
    {
      # eza and tree are installed via wrapped fish
      environment = {
        shellAliases = {
          t = "tree";
        };
      };

      custom.programs.print-config = {
        eza = /* sh */ ''moor --lang sh "${lib.getExe pkgs.custom.eza}"'';
      };
    };
}
