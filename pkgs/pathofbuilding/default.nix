# build this package standalone with the following command:
# nix-build default.nix
{pkgs ? import <nixpkgs> {}}:
with pkgs; let
  pobVersion = "2.28.0";
  pobSha256 = "sha256-IO6qUE6OcjNibljNzcJQlwji3DZqrBm7cvHedKuAwpM=";
  luacurlVersion = "0.3.13-1";
  # package lua-curl for luajit
  lua-curl =
    callPackage
    ({
      luajit,
      fetchFromGitHub,
    }:
      luajit.pkgs.buildLuarocksPackage rec {
        pname = "lua-curl";
        version = luacurlVersion;

        src = fetchFromGitHub {
          owner = "Lua-cURL";
          repo = "Lua-cURLv3";
          rev = "833e87c830bed05fe3910a33f573c202a48ba6d4";
          hash = "sha256-16oS4T8Sul8Qs7ymTLtB/dEqRzWZeRAR3VUsm/lKxT4=";
        };

        buildInputs = [curl];
        propagatedBuildInputs = [luajit];

        preConfigure = ''
          ln -s rockspecs/${pname}-${version}.rockspec .
        '';
      })
    {};
  pob-frontend = stdenv.mkDerivation {
    pname = "pobfrontend";
    version = "luajit";

    src = fetchgit {
      url = "https://gitlab.com/bcareil/pobfrontend.git";
      rev = "29feacd42e1f11274bad66514e6ad1a8d732ec21";
      hash = "sha256-4JKMyuTQEGqKTnai6h30FYyYvhiTnGRcNapB8cVrHxg=";
    };

    nativeBuildInputs = [
      pkg-config
      meson
      ninja
      lua-curl
    ];
    buildInputs = [
      libsForQt5.qt5.qtbase
      libsForQt5.qt5.qttools
      libsForQt5.qt5.wrapQtAppsHook
      libGL
      zlib
    ];

    mesonFlags = ["--buildtype=release"];

    installPhase = ''
      strip ./pobfrontend
      mkdir -p $out/bin
      cp ./pobfrontend $out/bin
    '';
  };
  pob-runtime-src = stdenv.mkDerivation {
    name = "pob-runtime-src";
    version = "1167199";

    src = fetchzip {
      url = "https://github.com/Openarl/PathOfBuilding/files/1167199/PathOfBuilding-runtime-src.zip";
      sha256 = "sha256-74ye6adtYWwVxu1kjCfEzHbKsOoO5/4g+anQemQmZY4=";
      stripRoot = false;
    };

    patches = [
      (fetchpatch {
        url = "https://aur.archlinux.org/cgit/aur.git/plain/lzip-linux.patch?h=path-of-building-community-git";
        sha256 = "sha256-nbyIArdM7tePGmuh1bkCUfWuf5qM9Ul0JuSjUAERL80=";
      })
    ];

    # everything else from now on is done in the lua directory
    prePatch = "cd LZip";

    nativeBuildInputs = [pkgconf zlib];

    dontBuild = true;

    installPhase =
      /*
      sh
      */
      ''
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
in
  # referenced from pob package on AUR
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=path-of-building-community-git
  stdenv.mkDerivation rec {
    pname = "path-of-building";
    version = pobVersion;

    src = fetchFromGitHub {
      owner = "PathOfBuildingCommunity";
      repo = "PathOfBuilding";
      rev = "v${pobVersion}";
      sha256 = pobSha256;
    };

    patches = [
      (fetchpatch {
        url = "https://aur.archlinux.org/cgit/aur.git/plain/PathOfBuilding-force-disable-devmode.patch?h=path-of-building-community-git";
        sha256 = "sha256-dCZZP3yj6rPZn5Z6yK9wJjn9vcHIXBwOtO/kuzK3YFc=";
      })
    ];

    nativeBuildInputs = [makeWrapper];

    dontBuild = true;

    installPhase =
      /*
      sh
      */
      ''
        mkdir -p $out/bin
        cp -r * $out
        cp ${lua-curl}/lib/lua/5.1/lcurl.so $out
        cp ${pob-runtime-src}/bin/lzip.so $out
        cp ${pob-frontend}/bin/pobfrontend $out

        # create a wrapper script for pobfrontend
        makeWrapper $out/pobfrontend $out/bin/path-of-building \
            --set LUA_PATH "$out/runtime/lua/?.lua;$out/runtime/lua/?/init.lua" \
            --run "cd $out"

        # create logos
        mkdir -p $out/share/pixmaps
        cp ${./PathOfBuilding-logo.png} $out/share/pixmaps/PathOfBuilding.png
        cp ${./PathOfBuilding-logo.svg} $out/share/pixmaps/PathOfBuilding.svg
        ln -sv "${desktopItem}/share/applications" $out/share
      '';

    desktopItem = makeDesktopItem {
      name = "Path of Building";
      desktopName = "Path of Building";
      comment = "Offline build planner for Path of Exile";
      exec = "path-of-building %U";
      terminal = false;
      type = "Application";
      icon = "PathOfBuilding";
      categories = ["Game"];
      keywords = ["poe" "pob" "pobc" "path" "exile"];
      mimeTypes = ["x-scheme-handler/pob"];
    };
  }
