{ config, lib, ... }:
{
  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;

    settings = {
      manager = {
        ratio = [
          0
          1
          1
        ];
        sort_by = "alphabetical";
        sort_sensitive = false;
        sort_reverse = false;
        linemode = "size";
        show_hidden = true;
      };
    };

    theme = {
      manager = {
        preview_hovered = {
          underline = false;
        };
        folder_offset = [
          1
          0
          1
          0
        ];
        preview_offset = [
          1
          1
          1
          1
        ];
      };

      status.separator_style = {
        fg = "red";
        bg = "red";
      };
    };

    keymap =
      let
        homeDir = "/persist/${config.home.homeDirectory}";
        shortcuts = {
          h = homeDir;
          dots = "${homeDir}/projects/dotfiles";
          cfg = "${homeDir}/.config";
          vd = "${homeDir}/Videos";
          vaa = "${homeDir}/Videos/Anime";
          vm = "${homeDir}/Videos/Movies";
          vt = "${homeDir}/Videos/TV";
          vtn = "${homeDir}/Videos/TV/New";
          pp = "${homeDir}/projects";
          pc = "${homeDir}/Pictures";
          ps = "${homeDir}/Pictures/Screenshots";
          pw = "${homeDir}/Pictures/Wallpapers";
          dd = "${homeDir}/Downloads";
          dp = "${homeDir}/Downloads/pending";
          dus = "${homeDir}/Downloads/pending/Unsorted";
        };
      in
      {
        # add keymaps for shortcuts
        input.prepend_keymap = lib.flatten (
          lib.mapAttrsToList (keys: loc: [
            # cd
            {
              on = [ "g" ] ++ lib.stringToCharacters keys;
              run = "cd ${loc}";
              desc = "cd to ${loc}";
            }
            # new tab
            {
              on = [ "t" ] ++ lib.stringToCharacters keys;
              run = "tab_create ${loc}";
              desc = "open new tab to ${loc}";
            }
            # mv
            {
              on = [ "m" ] ++ lib.stringToCharacters keys;
              run = [
                "yank --cut"
                "escape --visual --select"
                loc
              ];
              desc = "move selection to ${loc}";
            }
            # cp
            {
              on = [ "Y" ] ++ lib.stringToCharacters keys;
              run = [
                "yank"
                "escape --visual --select"
                loc
              ];
              desc = "copy selection to ${loc}";
            }
          ]) shortcuts
        );
      };
  };

  home.shellAliases = {
    y = "yazi";
  };
}
