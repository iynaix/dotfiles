{
  inputs,
  pkgs,
  ...
}:
inputs.devenv.lib.mkShell {
  inherit inputs pkgs;
  modules = [
    ({pkgs, ...}: {
      # devenv configuration
      packages = with pkgs; [
        alejandra
        ascii-image-converter # wfetch --wallpaper-ascii
        fastfetch
        imagemagick
      ];

      languages.nix.enable = true;
      languages.rust.enable = true;

      pre-commit = {
        hooks = {
          alejandra = {
            enable = true;
            excludes = ["generated.nix"];
          };
          deadnix = {
            enable = true;
            excludes = ["generated.nix"];
          };
          statix = {
            enable = true;
            excludes = ["generated.nix"];
          };
        };
        settings = {
          deadnix.edit = true;
        };
      };
    })
  ];
}
