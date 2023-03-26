{
  pkgs,
  config,
  user,
  lib,
  ...
}: {
  imports = [
    ./btop.nix
    ./git.nix
    ./direnv.nix
    ./ranger.nix
    ./tmux.nix
    ./zsh.nix
  ];

  options.iynaix.terminal = {
    font = lib.mkOption {
      type = lib.types.str;
      default = config.iynaix.font.monospace;
      description = "Font for the terminal.";
    };

    size = lib.mkOption {
      type = lib.types.int;
      default = 11;
      description = "Font size for the terminal.";
    };

    padding = lib.mkOption {
      type = lib.types.int;
      default = 12;
      description = "Padding for the terminal.";
    };

    opacity = lib.mkOption {
      type = lib.types.float;
      default = 0.6;
      description = "Opacity for the terminal.";
    };
  };

  options.iynaix.shortcuts = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = {
      h = "~";
      dots = "~/projects/dotfiles";
      c = "~/.config";
      vv = "~/Videos";
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

  config = {
    home-manager.users.${user} = {
      home = {
        packages = with pkgs; [
          bat
          fd
          fzf
          htop
          lazygit
          neofetch
          sd
          ugrep
        ];
      };
    };
  };
}
