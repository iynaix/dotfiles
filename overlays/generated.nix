# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  swww = {
    pname = "swww";
    version = "a4c5bdbf08f6ff1839aa76f162f540b822cabca3";
    src = fetchFromGitHub {
      owner = "LGFae";
      repo = "swww";
      rev = "a4c5bdbf08f6ff1839aa76f162f540b822cabca3";
      fetchSubmodules = false;
      sha256 = "sha256-huJnElxtHGmNd2I3zeDClPgfhfFPtb2y99FzR9i9JPc=";
    };
    date = "2024-01-16";
  };
  waybar = {
    pname = "waybar";
    version = "6e12f8122347ae279ae0fa1923acd6b908fa769c";
    src = fetchFromGitHub {
      owner = "Alexays";
      repo = "Waybar";
      rev = "6e12f8122347ae279ae0fa1923acd6b908fa769c";
      fetchSubmodules = false;
      sha256 = "sha256-YG/4LeOPtc0u/bLbFQ4yCyLSatrzPfE3a9X1+k8Ttpc=";
    };
    date = "2024-01-17";
  };
}
