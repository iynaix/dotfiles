{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        eza' = inputs.wrappers.lib.wrapPackage {
          inherit pkgs;
          package = pkgs.eza;
          flags = {
            "--icons" = { };
            "--group-directories-first" = { };
            "--header" = { };
            "--octal-permissions" = { };
            "--hyperlink" = { };
          };
        };
        eza-tree = pkgs.writeShellApplication {
          name = "tree";
          runtimeInputs = [ pkgs.eza ];
          text = # sh
            ''
              if [ $# -eq 0 ]; then
                  echo "No arguments provided"
                  exit 1
              fi

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

  flake.nixosModules.core =
    { pkgs, self, ... }:
    {
      environment = {
        shellAliases = {
          t = "tree";
          ls = "eza";
          ll = "eza -l";
          la = "eza -a";
          lt = "eza --tree";
          lla = "eza -la";
        };

        systemPackages = with self.packages.${pkgs.stdenv.hostPlatform.system}; [
          eza'
          eza-tree
        ];
      };
    };
}
