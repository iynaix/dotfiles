{ pkgs, user, lib, config, stdenv, ... }:
let
  pobVersion = "2.25.1";
  luacurlVersion = "0.3.13-1";
  # package lua-curl for luajit
  lua-curl = pkgs.callPackage
    ({ luajit, fetchFromGitHub }:
      luajit.pkgs.buildLuarocksPackage rec {
        pname = "lua-curl";
        version = luacurlVersion;

        src = fetchFromGitHub {
          owner = "Lua-cURL";
          repo = "Lua-cURLv3";
          rev = "833e87c830bed05fe3910a33f573c202a48ba6d4";
          hash = "sha256-16oS4T8Sul8Qs7ymTLtB/dEqRzWZeRAR3VUsm/lKxT4=";
        };

        buildInputs = [ pkgs.curl ];
        propagatedBuildInputs = [ luajit ];

        preConfigure = ''
          ln -s rockspecs/${pname}-${version}.rockspec .
        '';
      })
    { };
  pob-frontend = pkgs.stdenv.mkDerivation {
    pname = "pobfrontend";
    version = "luajit";

    src = pkgs.fetchgit {
      url = "https://gitlab.com/bcareil/pobfrontend.git";
      rev = "29feacd42e1f11274bad66514e6ad1a8d732ec21";
      hash = "sha256-4JKMyuTQEGqKTnai6h30FYyYvhiTnGRcNapB8cVrHxg=";
    };

    nativeBuildInputs = with pkgs; [
      pkg-config
      meson
      ninja
      lua-curl
    ];
    buildInputs = with pkgs; [
      libsForQt5.qt5.qtbase
      libsForQt5.qt5.qttools
      libsForQt5.qt5.wrapQtAppsHook
      libGL
      zlib
    ];

    mesonFlags = [ "--buildtype=release" ];

    installPhase = ''
      strip ./pobfrontend
      mkdir -p $out/bin
      cp ./pobfrontend $out/bin
    '';
  };

  pob-runtime-src = pkgs.stdenv.mkDerivation {
    name = "pob-runtime-src";
    version = "1167199";

    src = pkgs.fetchzip {
      url = "https://github.com/Openarl/PathOfBuilding/files/1167199/PathOfBuilding-runtime-src.zip";
      sha256 = "sha256-74ye6adtYWwVxu1kjCfEzHbKsOoO5/4g+anQemQmZY4=";
      stripRoot = false;
    };

    nativeBuildInputs = with pkgs; [
      pkgconf
      zlib
    ];

    dontBuild = true;

    installPhase = ''
      cd LZip
      g++ ''${CXXFLAGS} -W -Wall -fPIC -shared -o lzip.so \
        -I"$(pkgconf luajit --variable=includedir)" \
        lzip.cpp \
        ''${LDFLAGS} \
        -L"$(pkgconf luajit --variable=libdir)" \
        -l"$(pkgconf luajit --variable=libname)" \
        -lz
        mkdir -p $out/bin
        cp lzip.so $out/bin
    '';
  };

  # referenced from pob package on AUR
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=path-of-building-community-git
  path-of-building = pkgs.stdenv.mkDerivation rec {
    pname = "path-of-building";
    version = pobVersion;

    src = pkgs.fetchzip {
      url = "https://github.com/PathOfBuildingCommunity/PathOfBuilding/archive/refs/tags/v${pobVersion}.zip";
      sha256 = "sha256-3ZctM3sRd5fviAd4oHDLFXBpsP1VPRxVe0qor4RrvVE=";
    };

    dontBuild = true;

    installPhase = ''
      mkdir -p $out
      cp -r ${src}/* $out
      cp ${lua-curl}/lib/lua/5.1/lcurl.so $out
      cp ${pob-runtime-src}/bin/lzip.so $out
      cp ${pob-frontend}/bin/pobfrontend $out
    '';
  };
in
{
  home-manager.users.${user} = {
    # home.packages = [ lua-curl ];
    # home.packages = [ pobfrontend ];
    home.packages = [ path-of-building pob-runtime-src ];
  };
}
