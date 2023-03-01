{ pkgs, user, lib, config, stdenv, ... }:
let
  pobVersion = "2.25.1";
  luacurlVersion = "0.3.13";
  # package lua-curl for luajit
  lua-curl = pkgs.callPackage
    ({ luajit, fetchFromGitHub }:
      luajit.pkgs.buildLuarocksPackage rec {
        pname = "lua-curl";
        version = "${luacurlVersion}-1";

        src = fetchFromGitHub {
          owner = "Lua-cURL";
          repo = "Lua-cURLv3";
          ref = "v${luacurlVersion}";
          hash = "sha256-16oS4T8Sul8Qs7ymTLtB/dEqRzWZeRAR3VUsm/lKxT4=";
        };

        buildInputs = [ pkgs.curl ];
        propagatedBuildInputs = [ luajit ];

        preConfigure = ''
          ln -s rockspecs/${pname}-${version}.rockspec .
        '';

        # lib/lua/5.1/lcurl.so
      })
    { };
  # referenced from pob package on AUR
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=path-of-building-community-git
  src = pkgs.fetchFromGitHub {
    owner = "PathOfBuildingCommunity";
    repo = "PathOfBuilding";
    rev = "v${pobVersion}";
    hash = "sha256-ItJ8aX/WUfcAovxRsXXyWKBAI92hFloYIZiv7viPIdQ=";
  };

  pobfrontend = pkgs.fetchgit {
    url = "https://gitlab.com/bcareil/pobfrontend.git";
    rev = "29feacd42e1f11274bad66514e6ad1a8d732ec21";
    hash = "sha256-4JKMyuTQEGqKTnai6h30FYyYvhiTnGRcNapB8cVrHxg=";
  };
in
let
  path-of-building = pkgs.runCommand "path-of-building" { } ''
    mkdir $out
    echo $out > /home/${user}/projects/pob-path.txt

    cp -r ${src} $out/pob
    cp -r ${pobfrontend} $out/pobfrontend
  '';
in
{
  home-manager.users.${user} = {
    # home.packages = [ lua-curl ];
    home.packages = [ path-of-building ];
  };
}
