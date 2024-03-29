# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  hypridle = {
    pname = "hypridle";
    version = "4395339a2dc410bcf49f3e24f9ed3024fdb25b0a";
    src = fetchFromGitHub {
      owner = "hyprwm";
      repo = "hypridle";
      rev = "4395339a2dc410bcf49f3e24f9ed3024fdb25b0a";
      fetchSubmodules = false;
      sha256 = "sha256-ZSn3wXQuRz36Ta/L+UCFKuUVG6QpwK2QmRkPjpQprU4=";
    };
    date = "2024-03-11";
  };
  hyprlock = {
    pname = "hyprlock";
    version = "0ba5b7ee67ddc5e62b7e460ebe6a90b17f89b33f";
    src = fetchFromGitHub {
      owner = "hyprwm";
      repo = "hyprlock";
      rev = "0ba5b7ee67ddc5e62b7e460ebe6a90b17f89b33f";
      fetchSubmodules = false;
      sha256 = "sha256-7OBtrKKNPYYZzdcHt0L8aB8owIYi3JFqQV58FEFn/p4=";
    };
    date = "2024-03-27";
  };
  path-of-building = {
    pname = "path-of-building";
    version = "v2.41.1";
    src = fetchFromGitHub {
      owner = "PathOfBuildingCommunity";
      repo = "PathOfBuilding";
      rev = "v2.41.1";
      fetchSubmodules = false;
      sha256 = "sha256-Mi0/yoslvH6MyL4r23DHYNQac3aChsFCMZOIZIM1+dg=";
    };
  };
  swww = {
    pname = "swww";
    version = "cb8795de15cd55696f57bee514d7b6679c2b2a1a";
    src = fetchFromGitHub {
      owner = "LGFae";
      repo = "swww";
      rev = "cb8795de15cd55696f57bee514d7b6679c2b2a1a";
      fetchSubmodules = false;
      sha256 = "sha256-MtZH6kBcOa2YjdjKnKIjIryp+ex2FDyeTQE2HFCmKps=";
    };
    date = "2024-03-27";
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
}
