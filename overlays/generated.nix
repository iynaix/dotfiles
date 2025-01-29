# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  path-of-building = {
    pname = "path-of-building";
    version = "v2.49.3";
    src = fetchFromGitHub {
      owner = "PathOfBuildingCommunity";
      repo = "PathOfBuilding";
      rev = "v2.49.3";
      fetchSubmodules = false;
      sha256 = "sha256-ZpvSI3W2pWPy37PDT4T4NpgFSoS7bk5d59vvCL2nWnM=";
    };
  };
  swww = {
    pname = "swww";
    version = "3e2e2ba8f44469a1446138ee97d2988e22b093bf";
    src = fetchFromGitHub {
      owner = "LGFae";
      repo = "swww";
      rev = "3e2e2ba8f44469a1446138ee97d2988e22b093bf";
      fetchSubmodules = false;
      sha256 = "sha256-XBwgv80YfLZ70XYVEnR0nA7Rz5jP241D5FiwrTg7tDk=";
    };
    date = "2025-01-17";
  };
  wallust = {
    pname = "wallust";
    version = "b36e650a394d620b27ad5df3c88e2fccc3c9acd8";
    src = fetchgit {
      url = "https://codeberg.org/explosion-mental/wallust";
      rev = "b36e650a394d620b27ad5df3c88e2fccc3c9acd8";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sparseCheckout = [ ];
      sha256 = "sha256-keas1c6O+fr8ientFHzKsqnH5pH/Msw7MM3hbtKqYjM=";
    };
    date = "2025-01-23";
  };
  yazi-plugins = {
    pname = "yazi-plugins";
    version = "f202fa8969bd9c0c6ba6fb36066ae8044e73c9a7";
    src = fetchFromGitHub {
      owner = "yazi-rs";
      repo = "plugins";
      rev = "f202fa8969bd9c0c6ba6fb36066ae8044e73c9a7";
      fetchSubmodules = false;
      sha256 = "sha256-oXjOLLFF2NqLfbZFvAas65zTvWQYi+Qn/mx8WpauQK0=";
    };
    date = "2025-01-28";
  };
  yazi-time-travel = {
    pname = "yazi-time-travel";
    version = "85baafd0b18515ccf0851e8d35f9306ec98f3c40";
    src = fetchFromGitHub {
      owner = "iynaix";
      repo = "time-travel.yazi";
      rev = "85baafd0b18515ccf0851e8d35f9306ec98f3c40";
      fetchSubmodules = false;
      sha256 = "sha256-kOpj/GJ7xIFfJDsuTvced5MYiC4ZLA0TgsqvcRnyALI=";
    };
    date = "2024-12-13";
  };
  yt-dlp = {
    pname = "yt-dlp";
    version = "2025.01.26";
    src = fetchFromGitHub {
      owner = "yt-dlp";
      repo = "yt-dlp";
      rev = "2025.01.26";
      fetchSubmodules = false;
      sha256 = "sha256-bjvyyCvUpZNGxkFz2ce6pXDSKXJROKZphs9RV4CBs5M=";
    };
  };
}
