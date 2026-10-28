{
  tags = [ "wm" ];

  config =
    {
      pkgs,
      ...
    }:
    {
      config = {
        environment.systemPackages = [
          (pkgs.callPackage ./_package.nix { })
        ];
      };
    };
}
