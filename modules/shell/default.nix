{ pkgs, user, lib, config, ... }: {
  imports = [ ./git.nix ./ranger.nix ./tmux.nix ./zsh.nix ];

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
      pcb = "~/projects/coinfc-backend";
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
        packages = with pkgs; [ bat bottom htop lazygit neofetch ];

        file."bin" = {
          source = ./bin;
          recursive = true;
        };
      };

      # potential vifm shortcuts
      # file.".config/vifm/vifmrc".text = lib.mkAfter (lib.concatStringsSep "\n"
      #   (lib.mapAttrsToList
      #     (name: value: (lib.concatStringsSep "\n" [
      #       "map g${name} :cd ${value}"
      #       "map t${name} <tab>:cd ${value} <CR><tab>"
      #       "map M${name} <tab>:cd ${value} <CR><tab>:mo<CR>"
      #       "map Y${name} <tab>:cd ${value} <CR><tab>:co<CR>"
      #     ]))
      #     config.iynaix.shortcuts));
    };
  };
}
