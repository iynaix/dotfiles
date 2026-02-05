{ self, ... }:
let
  drv =
    {
      sources,
      lib,
      mpvScripts,
      configLua ? "",
    }:
    let
      source = sources.mpv-cut;
    in
    mpvScripts.buildLua (
      source
      // {
        version = "0-unstable-${source.date}";

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
      }
    );
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages.mpv-cut = pkgs.callPackage drv {
        sources = self.libCustom.nvFetcherSources pkgs;
      };
    };
}
