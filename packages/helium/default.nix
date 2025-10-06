{
  callPackage,
  stdenv,
  lib,
  appimageTools,
  makeWrapper,
}:
let
  pname = "helium";
  sources = callPackage ./generated.nix { };
  source =
    (
      if stdenv.hostPlatform.system == "x86_64-linux" then
        sources.helium-x86_64
      else if stdenv.hostPlatform.system == "aarch64-linux" then
        sources.helium-arm64
      else
        throw "unsupported system"
    )
    // {
      inherit pname;
    };
  appimageContents = appimageTools.extract source;
in
appimageTools.wrapType2 (
  source
  // {
    nativeBuildInputs = [ makeWrapper ];
    extraInstallCommands = ''
      wrapProgram $out/bin/${pname} \
          --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"

      install -m 444 -D ${appimageContents}/${pname}.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace 'Exec=AppRun' 'Exec=${pname}'
      cp -r ${appimageContents}/usr/share/icons $out/share
    '';

    meta = {
      description = "Private, fast, and honest web browser";
      homepage = "https://helium.computer/";
      maintainers = [ lib.maintainers.iynaix ];
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    };
  }
)
