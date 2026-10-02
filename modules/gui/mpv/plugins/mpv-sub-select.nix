{
  packages =
    { pkgs, ... }:
    {
      mpv-sub-select = pkgs.mpvScripts.buildLua {
        pname = "mpv-sub-select";
        version = "0-unstable-2025-04-04";

        src = pkgs.fetchFromGitHub {
          owner = "CogentRedTester";
          repo = "mpv-sub-select";
          rev = "26d24a0fd1d69988eaedda6056a2c87d0a55b6cb";
          hash = "sha256-+eVga4b7KIBnfrtmlgq/0HNjQVS3SK6YWVXCPvOeOOc=";
        };

        dontBuild = true;

        scriptPath = "sub-select.lua";

        meta = {
          description = "Automatically skip chapters based on title";
          homepage = "https://github.com/CogentRedTester/mpv-sub-select";
        };
      };
    };
}
