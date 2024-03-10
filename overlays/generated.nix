# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  hypridle = {
    pname = "hypridle";
    version = "029f08805a2297966d295a52a6e62c3801926a52";
    src = fetchFromGitHub {
      owner = "hyprwm";
      repo = "hypridle";
      rev = "029f08805a2297966d295a52a6e62c3801926a52";
      fetchSubmodules = false;
      sha256 = "sha256-xi7yscjt7t8tFcJDgHzxgW15Obcp7dEghG41f6tUmRc=";
    };
    date = "2024-02-29";
  };
  hyprlock = {
    pname = "hyprlock";
    version = "21d9efe5c94f1a292d181af70b32059509eada68";
    src = fetchFromGitHub {
      owner = "hyprwm";
      repo = "hyprlock";
      rev = "21d9efe5c94f1a292d181af70b32059509eada68";
      fetchSubmodules = false;
      sha256 = "sha256-MVPKRGV9eZWvFseddNWI+nNeKQHjePU6SC/2ZyJP1m8=";
    };
    date = "2024-03-10";
  };
  path-of-building = {
    pname = "path-of-building";
    version = "v2.39.3";
    src = fetchFromGitHub {
      owner = "PathOfBuildingCommunity";
      repo = "PathOfBuilding";
      rev = "v2.39.3";
      fetchSubmodules = false;
      sha256 = "sha256-W4MmncDfeiuN7VeIeoPHEufTb9ncA3aA8F0JNhI9Z/o=";
    };
  };
  swww = {
    pname = "swww";
    version = "24cc0c34c3262bee688a21070c7e41e637c03d71";
    src = fetchFromGitHub {
      owner = "LGFae";
      repo = "swww";
      rev = "24cc0c34c3262bee688a21070c7e41e637c03d71";
      fetchSubmodules = false;
      sha256 = "sha256-QfIHfB1/5PTWHSWnwORmDsfAQzuvkbggoQm2YixY6ZU=";
    };
    date = "2024-03-04";
  };
  wallust = {
    pname = "wallust";
    version = "104d99fcb4ada743d45de76caa48cd899b021601";
    src = fetchgit {
      url = "https://codeberg.org/explosion-mental/wallust.git";
      rev = "104d99fcb4ada743d45de76caa48cd899b021601";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "sha256-gGyxRdv2I/3TQWrTbUjlJGsaRv4SaNE+4Zo9LMWmxk8=";
    };
    date = "2024-03-08";
  };
  waybar = {
    pname = "waybar";
    version = "4c46d7d245a6c06644d6a0e8857f7140556202ce";
    src = fetchFromGitHub {
      owner = "Alexays";
      repo = "Waybar";
      rev = "4c46d7d245a6c06644d6a0e8857f7140556202ce";
      fetchSubmodules = false;
      sha256 = "sha256-9zUqV1wxUAuRRBMQCUZEf5FjIKMeTEhWTLOfL4+9EiE=";
    };
    date = "2024-03-05";
  };
}
