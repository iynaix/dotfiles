{ config, lib, ... }:
let
  homeDir = config.home.homeDirectory;
in
{
  options.custom.shortcuts = lib.mkOption {
    type = with lib.types; attrsOf str;
    default = {
      h = homeDir;
      dots = "${homeDir}/projects/dotfiles";
      cfg = "${homeDir}/.config";
      vd = "${homeDir}/Videos";
      vaa = "${homeDir}/Videos/Anime";
      vac = "${homeDir}/Videos/Anime/Current";
      vC = "${homeDir}/Videos/Courses";
      vm = "${homeDir}/Videos/Movies";
      vt = "${homeDir}/Videos/TV";
      vtc = "${homeDir}/Videos/TV/Current";
      vtn = "${homeDir}/Videos/TV/New";
      pp = "${homeDir}/projects";
      PC = "${homeDir}/Pictures";
      Ps = "${homeDir}/Pictures/Screenshots";
      Pw = "${homeDir}/Pictures/Wallpapers";
      dd = "${homeDir}/Downloads";
      dp = "${homeDir}/Downloads/pending";
      dus = "${homeDir}/Downloads/pending/Unsorted";
    };
    description = "Shortcuts for navigating across multiple terminal programs.";
  };
}
