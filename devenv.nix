{ inputs, system, ... }:
inputs.devenv.lib.mkShell {
  inherit inputs;

  # use nixfmt-rfc-style for nixfmt
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [
      (_: prev: {
        # need gtk support for opencv to show the preview window
        nixfmt = prev.nixfmt-rfc-style;
      })
    ];
  };

  modules = [
    (
      { pkgs, ... }:
      {
        # devenv configuration
        packages = with pkgs; [
          nixfmt-rfc-style
          ascii-image-converter # for  wfetch --wallpaper-ascii
          fastfetch
          imagemagick
        ];

        languages.nix.enable = true;
        languages.rust.enable = true;

        pre-commit = {
          hooks = {
            deadnix = {
              enable = true;
              excludes = [ "generated.nix" ];
            };
            nixfmt = {
              enable = true;
              excludes = [ "generated.nix" ];
            };
            statix = {
              enable = true;
              excludes = [ "generated.nix" ];
            };
          };
          settings = {
            deadnix.edit = true;
          };
        };
      }
    )
  ];
}
