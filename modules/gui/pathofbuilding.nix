{
  perSystem =
    { pkgs, ... }:
    let
      source = (pkgs.callPackage ../../_sources/generated.nix { }).path-of-building;
      pob-data = pkgs.path-of-building.passthru.data.overrideAttrs source;
    in
    {
      packages.path-of-building = pkgs.path-of-building.overrideAttrs {
        inherit (source) version;
        __intentionallyOverridingVersion = true;

        preFixup = ''
          qtWrapperArgs+=(
            --set LUA_PATH "$LUA_PATH"
            --set LUA_CPATH "$LUA_CPATH"
            --chdir "${pob-data}"
          )

          # fix for wayland
          substituteInPlace $out/share/applications/path-of-building.desktop \
            --replace-fail "pobfrontend" "env -u WAYLAND_DISPLAY pobfrontend"
        '';
      };
    };

  flake.nixosModules.path-of-building =
    { self, pkgs, ... }:
    {
      environment.systemPackages = [ self.packages.${pkgs.system}.path-of-building ];

      custom.programs.hyprland.settings = {
        # starts floating for some reason?
        windowrule = [ "tile,class:(pobfrontend)" ];
      };

      custom.persist = {
        home.directories = [ ".local/share/pobfrontend" ];
      };
    };
}
