{ lib, ... }:
let
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
      # silently allow host and tag attributes instead of quietly failing
      host = if module ? host then [ module.host ] else null;
      hosts = module.hosts or host;

      tag = if module ? tag then [ module.tag ] else null;
      tags = module.tags or tag;

      validTags = module.validTags or null;
      invalidTags =
        if (tags == null || validTags == null) then
          [ ]
        else
          builtins.filter (t: !(lib.elem t validTags)) tags;
    in
    assert lib.assertMsg (
      invalidTags == [ ]
    ) "Module contains invalid tags: ${toString invalidTags}. Allowed tags are: ${toString validTags}";

    if hosts == null && tags == null then
      true
    else
      (hosts != null && lib.elem hostInfo.name hosts)
      || (tags != null && lib.any (t: lib.elem t hostInfo.tags) tags);
in
{
  inherit recursivelyImport;

  mkHost =
    name: args:
    let
      hostInfo = args // {
        inherit name;
        system = args.system or "x86_64-linux";
        tags = args.tags or [ ];
      };
      filteredModules = builtins.filter (m: (m.enabled or true) && matchesHost m hostInfo) (
        lib.concatMap loadModules (args.modules or [ ])
      );
    in
    lib.nixosSystem {
      inherit (hostInfo) system;
      specialArgs = (hostInfo.specialArgs or { }) // {
        inherit (hostInfo) system tags;
        host = name;
      };
      modules = builtins.filter (c: c != null) (map (m: m.config or null) filteredModules);
    };

  mkPackages =
    pkgs: modules: packagesArgs:
    lib.foldl' (
      acc: m:
      acc
      // (
        if m ? packages then
          m.packages (
            {
              inherit pkgs;
              inherit (pkgs.stdenv.hostPlatform) system;
            }
            // packagesArgs
          )
        else
          { }
      )
    ) { } (lib.concatMap loadModules modules);
}
