{lib, ...}: {
  options.iynaix.shortcuts = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = {
      h = "~";
      dots = "~/projects/dotfiles";
      c = "~/.config";
      vd = "~/Videos";
      vaa = "~/Videos/Anime";
      vac = "~/Videos/Anime/Current";
      vC = "~/Videos/Courses";
      vm = "~/Videos/Movies";
      vu = "~/Videos/US";
      vc = "~/Videos/US/Current";
      vn = "~/Videos/US/New";
      pp = "~/projects";
      pcf = "~/projects/coinfc";
      pe = "~/projects/ergodox-layout";
      PP = "~/Pictures";
      Ps = "~/Pictures/Screenshots";
      Pw = "~/Pictures/Wallpapers";
      dd = "~/Downloads";
      dp = "~/Downloads/pending";
      du = "~/Downloads/pending/Unsorted";
      dk = "/run/media/iynaix";
    };
    description = "Shortcuts for navigating across multiple terminal programs.";
  };
}
