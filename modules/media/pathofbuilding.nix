{ pkgs, user, lib, config, stdenv, ... }:
let
  # referenced from pob package on AUR
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=path-of-building-community-git
  # path-of-building = pkgs.stdenv.mkDerivation rec {
  #   # source=(
  #   # 	'git+https://github.com/PathOfBuildingCommunity/PathOfBuilding'
  #   # 	'git+https://gitlab.com/bcareil/pobfrontend.git#branch=luajit'
  #   # 	'git+https://github.com/Lua-cURL/Lua-cURLv3'
  #   # 	'https://github.com/Openarl/PathOfBuilding/files/1167199/PathOfBuilding-runtime-src.zip'
  #   # 	'PathOfBuilding.sh'
  #   # 	'lzip-linux.patch'
  #   # 	'PathOfBuilding-force-disable-devmode.patch'
  #   # 	'PathOfBuilding-logo.svg'
  #   # 	'PathOfBuilding-logo.png'
  #   # 	'PathOfBuildingCommunity.desktop'
  #   # )
  #   pname = "path-of-building";
  #   version = "2.25.1";
  #   src = pkgs.fetchFromGitHub {
  #     owner = "PathOfBuildingCommunity";
  #     repo = "PathOfBuilding";
  #     rev = "v${version}";
  #     hash = "sha256-ItJ8aX/WUfcAovxRsXXyWKBAI92hFloYIZiv7viPIdQ=";
  #   };
  #   buildInputs = with pkgs; [ luajit ];

  #   installPase = ''
  #     echo $out
  #   '';
  # };
  #####################################################################
  lua-curl = pkgs.callPackage
    ({ luajit, fetchFromGitHub }:
      luajit.pkgs.buildLuarocksPackage rec {
        pname = "lua-curl";
        version = "0.3.13-1";

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





in
{
  home-manager.users.${user} = {
    home.packages = [ lua-curl ];
  };
}
