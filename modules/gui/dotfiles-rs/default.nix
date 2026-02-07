{ lib, ... }:
{
  flake.nixosModules.core =
    { pkgs, ... }:
    {
      options.custom = {
        programs.dotfiles-rs = lib.mkPackageOption pkgs "custom.dotfiles-rs" { };
      };
    };

  flake.nixosModules.wm =
    { config, pkgs, ... }:
    {
      custom.programs = {
        dotfiles-rs = pkgs.custom.dotfiles-rs.override {
          inherit (pkgs) pqiv;
          extraPackages = [ pkgs.custom.noctalia-ipc ];
        };
      };

      environment.systemPackages = [ config.custom.programs.dotfiles-rs ];
    };
}
