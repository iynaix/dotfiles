{
  src,
  version,
  lib,
  appimageTools,
  makeWrapper,
  flags ? [ ],
}:
let
  pname = "helium";
in
appimageTools.wrapType2 (finalAttrs: {
  inherit pname version src;

  nativeBuildInputs = [ makeWrapper ];
  extraInstallCommands = /* sh */ ''
    wrapProgram $out/bin/${pname} \
        --set-default XDG_DATA_HOME "$HOME/.local/share" \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
        ${lib.concatMapStringsSep " \\\n" (f: "--add-flags \"${f}\"") flags}

    install -m 444 -D ${finalAttrs.contents}/${pname}.desktop -t $out/share/applications
    substituteInPlace $out/share/applications/${pname}.desktop \
      --replace 'Exec=AppRun' 'Exec=${pname}'
    cp -r ${finalAttrs.contents}/usr/share/icons $out/share
  '';

  # pass through files from the root fs
  extraBwrapArgs = [
    # chromium policies
    "--ro-bind-try /etc/chromium/policies/managed/default.json /etc/chromium/policies/managed/default.json"
    # xdg scheme-handlers
    "--ro-bind-try /etc/xdg/ /etc/xdg/"
  ];

  meta = {
    description = "Private, fast, and honest web browser";
    homepage = "https://helium.computer/";
    maintainers = [ lib.maintainers.iynaix ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
})
