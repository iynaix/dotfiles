# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  rofi-themes = {
    pname = "rofi-themes";
    version = "f7bc0216ca7bdb011266615f02385989384b72a4";
    src = fetchFromGitHub {
      owner = "adi1090x";
      repo = "rofi";
      rev = "f7bc0216ca7bdb011266615f02385989384b72a4";
      fetchSubmodules = false;
      sha256 = "sha256-FqX75EwWNjy4IMh7xfxRUnXk65A/mZL65yRZuQi6IqA=";
    };
    date = "2024-10-05";
  };
}
