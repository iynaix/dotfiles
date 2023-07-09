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
    ./rice
    ./renameutils.nix
    ./tmux.nix
    ./zsh.nix
  ];

  options.iynaix.terminal = {
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.kitty;
      description = "Terminal package to use.";
    };

    exec = lib.mkOption {
      type = lib.types.str;
      default = "${lib.getExe config.iynaix.terminal.package}";
      description = "Terminal command to execute other programs.";
      example = "alacritty -e";
    };

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
      default = 0.8;
      description = "Opacity for the terminal.";
    };

    # create a fake gnome-terminal shell script so xdg terminal applications open in the correct terminal
    # https://unix.stackexchange.com/a/642886
    fakeGnomeTerminal = lib.mkOption {
      type = lib.types.package;
      description = "Fake gnome-terminal shell script so gnome opens terminal applications in the correct terminal.";
    };
  };

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

  config = {
    environment.systemPackages = [config.iynaix.terminal.fakeGnomeTerminal];

    home-manager.users.${user} = {
      home = {
        packages = with pkgs; [
          bat
          fd
          fzf
          htop
          lazygit
          sd
          ugrep
        ];
      };
    };
  };
}
