{
  flake.modules.nixos.programs_zed-editor =
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
