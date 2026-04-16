{ lib, ... }:
{
  flake.modules.nixos.core =
    { pkgs, ... }:
    {
      options.custom = {
        programs.dotfiles-rs = lib.mkPackageOption pkgs "custom.dotfiles-rs" { };
      };
    };

  flake.modules.nixos.wm =
    { config, pkgs, ... }:
    {
      custom.programs = {
        dotfiles-rs = pkgs.custom.dotfiles-rs.override {
          inherit (pkgs) pqiv;
          extraPackages = [ pkgs.noctalia-shell ];
        };
      };

      environment.systemPackages = [ config.custom.programs.dotfiles-rs ];
    };
}
