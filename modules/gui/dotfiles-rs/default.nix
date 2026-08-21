{
  tags = [ "wm" ];

  config =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.custom = {
        programs.dotfiles-rs = lib.mkPackageOption pkgs "custom.dotfiles-rs" { };
      };

      config = {
        custom.programs = {
          dotfiles-rs = pkgs.custom.dotfiles-rs.override {
            inherit (pkgs) pqiv;
            extraPackages = [ pkgs.noctalia ];
          };
        };

        environment.systemPackages = [ config.custom.programs.dotfiles-rs ];
      };
    };
}
