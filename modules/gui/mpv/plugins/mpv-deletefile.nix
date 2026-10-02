{
  packages =
    { lib, pkgs, ... }:
    {
      mpv-deletefile = pkgs.mpvScripts.buildLua {
        pname = "mpv-deletefile";
        version = "0-unstable-2025-12-06";

        src = pkgs.fetchFromGitHub {
          owner = "zenyd";
          repo = "mpv-scripts";
          rev = "62f4bb313c6cb6366672e78dea940e9da8fec84a";
          hash = "sha256-9gO+GkNoGsxAbMRrBWu0FfXEQtyTmHivlaxlYLpV2YM=";
        };

        dontBuild = true;

        scriptPath = "delete_file.lua";

        meta = {
          description = "Deletes files played through mpv";
          homepage = "https://github.com/zenyd/mpv-scripts";
          license = lib.licenses.gpl3;
        };
      };
    };
}
