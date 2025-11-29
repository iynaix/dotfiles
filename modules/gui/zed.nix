{
  flake.nixosModules.gui =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.zed-editor ];

      custom.persist = {
        home.directories = [
          ".cache/zed"
          ".config/zed"
          ".local/share/zed"
        ];
      };
    };
}
