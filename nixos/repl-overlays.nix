info: _final: prev:
let
  optionalAttrs = predicate: attrs: if predicate then attrs else { };
  system = info.currentSystem;
in
optionalAttrs (prev ? legacyPackages && prev.legacyPackages ? ${system}) rec {
  pkgs = prev.legacyPackages.${system};
  inherit (pkgs) lib;
}
// optionalAttrs (prev ? packages && prev.packages ? ${system}) {
  packages = prev.packages.${system};
}
