{
  description = "iynaix's dotfiles";

  outputs =
    { self, ... }:
    let
      inputs = import ./nix/tamal { };

      inherit (inputs.nixpkgs.lib.fileset) toList fileFilter;
      import-tree =
        path:
        toList (fileFilter (file: file.hasExt "nix" && !(inputs.nixpkgs.lib.hasPrefix "_" file.name)) path);
    in
    inputs.flake-parts.lib.mkFlake
      {
        inherit self inputs;
      }
      {
        imports = import-tree ./modules;

        flake.templates = import ./templates;
      };
}
