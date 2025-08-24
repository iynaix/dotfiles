{
  callPackage,
  path-of-building,
}:
let
  source = (callPackage ./generated.nix { }).path-of-building;
in
path-of-building.overrideAttrs {
  inherit (source) version;
  __intentionallyOverridingVersion = true;

  preFixup =
    let
      data = path-of-building.passthru.data.overrideAttrs source;
    in
    # sh
    ''
      qtWrapperArgs+=(
        --set LUA_PATH "$LUA_PATH"
        --set LUA_CPATH "$LUA_CPATH"
        --chdir "${data}"
      )

      # fix for wayland
      substituteInPlace $out/share/applications/path-of-building.desktop \
        --replace-fail "pobfrontend" "env -u WAYLAND_DISPLAY pobfrontend"
    '';
}
