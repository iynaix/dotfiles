# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  mpv-modernx = {
    pname = "mpv-modernx";
    version = "0.6.0";
    src = fetchFromGitHub {
      owner = "cyl0";
      repo = "ModernX";
      rev = "0.6.0";
      fetchSubmodules = false;
      sha256 = "sha256-Gpofl529VbmdN7eOThDAsNfNXNkUDDF82Rd+csXGOQg=";
    };
  };
}
