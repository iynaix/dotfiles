{
  inputs,
  lib,
  self,
  ...
}:
let
  systems = [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];

  recursivelyImport =
    path:
    let
      files = lib.fileset.toList (lib.fileset.fileFilter (file: file.hasExt "nix") path);

      isUnderscored =
        file:
        let
          relative = lib.removePrefix (toString path + "/") (toString file);
          parts = lib.splitString "/" relative;
        in
        lib.any (part: lib.hasPrefix "_" part) parts;
    in
    lib.filter (file: !isUnderscored file) files;

  loadModules =
    dir:
    map (
      path:
      let
        m = import path;
      in
      if builtins.isAttrs m then m else { config = m; }
    ) (recursivelyImport dir);

  matchesHost =
    module: hostInfo:
    let
      hosts = module.hosts or null;
      tags = module.tags or null;
    in
    if hosts == null && tags == null then
      true
    else
      (hosts != null && lib.elem hostInfo.name hosts)
      || (tags != null && lib.any (t: lib.elem t hostInfo.tags) tags);
in
{
  inherit systems recursivelyImport;

  # provide package for each system
  forAllSystems =
    f:
    inputs.nixpkgs.lib.genAttrs systems (
      system:
      f (
        import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }
      )
    );

  mkHost =
    name: info:
    let
      hostInfo = info // {
        inherit name;
        tags = info.tags or [ ];
      };
      applicable = builtins.filter (m: (m.enabled or true) && matchesHost m hostInfo) (
        loadModules ./modules
      );
    in
    lib.nixosSystem rec {
      inherit (hostInfo) system;
      specialArgs = {
        inherit
          inputs
          self
          system
          ;
        host = name;
        inherit (hostInfo) tags;
        libCustom = import ./lib.nix {
          inherit lib;
          pkgs = inputs.nixpkgs.legacyPackages.${system};
        };
        user = "iynaix";
      }
      // (hostInfo.specialArgs or { });
      modules = builtins.filter (c: c != null) (map (m: m.config or null) applicable);
    };

  addTags = info: extraTags: (info // { tags = (info.tags or [ ]) ++ extraTags; });

  mkPackages =
    pkgs:
    lib.foldl' (
      acc: m:
      acc
      // (
        if m ? packages then
          m.packages {
            inherit
              inputs
              lib
              pkgs
              self
              ;
            inherit (pkgs.stdenv.hostPlatform) system;
            libCustom = import ./lib.nix { inherit lib pkgs; };
          }
        else
          { }
      )
    ) { } (loadModules ./modules);
}
