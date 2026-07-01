{
  description = "iynaix's dotfiles";

  outputs =
    { self, ... }@args:
    let
      # inputs from tack
      inputs = (import ./.tack) {
        overrides = args.tackOverrides or { };
      };

      inherit (inputs.nixpkgs.lib.fileset) toList fileFilter;
      import-tree =
        path:
        toList (fileFilter (file: file.hasExt "nix" && !(inputs.nixpkgs.lib.hasPrefix "_" file.name)) path);
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs self; } {
      imports = import-tree ./modules;

      flake.templates = import ./templates;
    };
}
