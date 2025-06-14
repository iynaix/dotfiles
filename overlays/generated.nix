# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  swww = {
    pname = "swww";
    version = "7ceddc01359d4af29ec1db8a7b390290126626b8";
    src = fetchFromGitHub {
      owner = "LGFae";
      repo = "swww";
      rev = "7ceddc01359d4af29ec1db8a7b390290126626b8";
      fetchSubmodules = false;
      sha256 = "sha256-qvxG8UhO7MsS0lWVGfHUsBKevAa+VJe41NrcX1ZCJdU=";
    };
    date = "2025-06-06";
  };
  wallust = {
    pname = "wallust";
    version = "d8f1acf4259b7513679238e427d836682d620fe8";
    src = fetchgit {
      url = "https://codeberg.org/explosion-mental/wallust";
      rev = "d8f1acf4259b7513679238e427d836682d620fe8";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sparseCheckout = [ ];
      sha256 = "sha256-XbCEVrR4utBd168zmw96OlzWRbtdtt3bAdY/EY0Ddgk=";
    };
    date = "2025-06-02";
  };
  yazi-plugins = {
    pname = "yazi-plugins";
    version = "63f9650e522336e0010261dcd0ffb0bf114cf912";
    src = fetchFromGitHub {
      owner = "yazi-rs";
      repo = "plugins";
      rev = "63f9650e522336e0010261dcd0ffb0bf114cf912";
      fetchSubmodules = false;
      sha256 = "sha256-ZCLJ6BjMAj64/zM606qxnmzl2la4dvO/F5QFicBEYfU=";
    };
    date = "2025-05-31";
  };
  yazi-time-travel = {
    pname = "yazi-time-travel";
    version = "7e0179e15a41a4a42b6d0b5fa6dd240c9b4cf0d2";
    src = fetchFromGitHub {
      owner = "iynaix";
      repo = "time-travel.yazi";
      rev = "7e0179e15a41a4a42b6d0b5fa6dd240c9b4cf0d2";
      fetchSubmodules = false;
      sha256 = "sha256-ZZgn5rsBzvZcnDWZfjMBPRg9QUz4FTq5UIPWfnwXHQs=";
    };
    date = "2025-02-14";
  };
  yt-dlp = {
    pname = "yt-dlp";
    version = "2025.05.22";
    src = fetchFromGitHub {
      owner = "yt-dlp";
      repo = "yt-dlp";
      rev = "2025.05.22";
      fetchSubmodules = false;
      sha256 = "sha256-Ahdu52dTbRz+8c06yQ6QOTVcbVYP2d1iYjYyjKDi8Wk=";
    };
  };
}
