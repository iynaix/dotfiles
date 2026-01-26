{ lib, ... }:
{
  flake.nixosModules.core =
    { pkgs, ... }:
    let
      flags = "--cmd cd";
    in
    {
      environment = {
        systemPackages = [ pkgs.zoxide ];

        shellAliases = {
          z = "zoxide query -i";
        };
      };

      # zoxide is initialized via `zoxide init fish <flags> | source` and is
      # therefore not wrapped with flags
      programs = {
        bash.interactiveShellInit = lib.mkAfter ''
          eval "$(${lib.getExe pkgs.zoxide} init bash ${flags} )"
        '';

        fish.interactiveShellInit = lib.mkAfter ''
          ${lib.getExe pkgs.zoxide} init fish ${flags} | source
        '';
      };

      custom.persist = {
        home = {
          cache.directories = [ ".local/share/zoxide" ];
        };
      };
    };
}
