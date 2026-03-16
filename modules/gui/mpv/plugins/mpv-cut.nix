{
  perSystem =
    { pkgs, ... }:
    let
      drv =
        {
          lib,
          fetchFromGitHub,
          mpvScripts,
          configLua ? "",
        }:
        mpvScripts.buildLua {
          pname = "mpv-cut";
          src = fetchFromGitHub {
            owner = "familyfriendlymikey";
            repo = "mpv-cut";
            rev = "3b18f1161ffb2ff822c88cb97e099772d4b3c26d";
            sha256 = "sha256-c4NHJM1qeXXBz8oyGUzS9QiAzRYiNKjmArM1K0Q2Xo0=";
          };

          version = "0-unstable-2023-11-22";

          dontBuild = true;

          scriptPath = "main.lua";

          postInstall = lib.optionalString (configLua != "") ''
            mkdir -p $out/share/mpv/scripts
            cat << 'EOF' > $out/share/mpv/scripts/config.lua
            ${configLua}
            EOF
          '';

          meta = {
            description = "An mpv plugin for cutting videos incredibly quickly.";
            homepage = "https://github.com/familyfriendlymikey/mpv-cut";
            maintainers = [ lib.maintainers.iynaix ];
          };
        };
    in
    {
      packages.mpv-cut = pkgs.callPackage drv { };
    };
}
