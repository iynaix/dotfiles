{
  config,
  dots,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    flatten
    mapAttrsToList
    mkMerge
    stringToCharacters
    ;
  mkYaziPlugin = name: text: {
    "${name}" = toString (pkgs.writeTextDir "${name}.yazi/main.lua" text) + "/${name}.yazi";
  };
in
mkMerge [
  {
    programs.yazi = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;

      plugins = {
        full-border = "${pkgs.custom.yazi-plugins.src}/full-border.yazi";
        git = "${pkgs.custom.yazi-plugins.src}/git.yazi";
        time-travel = pkgs.custom.yazi-time-travel.src;
      };

      initLua = # lua
        ''
          require("full-border"):setup({ type = ui.Border.ROUNDED })
          require("git"):setup()
        '';

      settings = {
        log = {
          enabled = true;
        };
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
        opener = {
          # activate direnv before opening files
          # https://github.com/sxyazi/yazi/discussions/1083
          edit = [
            {
              run = "direnv exec . $EDITOR $1";
              block = true;
            }
          ];
        };
        # settings for plugins
        plugin = {
          prepend_fetchers = [
            {
              id = "git";
              name = "*";
              run = "git";
            }
            {
              id = "git";
              name = "*/";
              run = "git";
            }
          ];
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

        mode = {
          normal_main = {
            bg = "cyan";
          };
          # normal_alt = {
          #   bg = "cyan";
          # };
        };
      };

      keymap =
        let
          homeDir = "/persist${config.home.homeDirectory}";
          shortcuts = {
            h = homeDir;
            inherit dots;
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
          manager.prepend_keymap =
            [
              # dropping to shell
              {
                on = "!";
                run = # sh
                  ''shell "$SHELL" --block --confirm'';
                desc = "Open shell here";
              }
              # close input by a single Escape press
              {
                on = "<Esc>";
                run = "close";
                desc = "Cancel input";
              }
              # cd back to root of current git repo
              {
                on = [
                  "g"
                  "r"
                ];
                run = # sh
                  ''shell 'ya pub dds-cd --str "$(git rev-parse --show-toplevel)"' --confirm'';
                desc = "Cd to root of current git repo";
              }
            ]
            ++ flatten (
              mapAttrsToList (keys: loc: [
                # cd
                {
                  on = [ "g" ] ++ stringToCharacters keys;
                  run = "cd ${loc}";
                  desc = "cd to ${loc}";
                }
                # new tab
                {
                  on = [ "t" ] ++ stringToCharacters keys;
                  run = "tab_create ${loc}";
                  desc = "open new tab to ${loc}";
                }
                # mv
                {
                  on = [ "m" ] ++ stringToCharacters keys;
                  run = [
                    "yank --cut"
                    "escape --visual --select"
                    loc
                  ];
                  desc = "move selection to ${loc}";
                }
                # cp
                {
                  on = [ "Y" ] ++ stringToCharacters keys;
                  run = [
                    "yank"
                    "escape --visual --select"
                    loc
                  ];
                  desc = "copy selection to ${loc}";
                }
              ]) shortcuts
            )
            ++ [
              {
                on = [
                  "z"
                  "h"
                ];
                run = "plugin time-travel prev";
                desc = "Go to previous snapshot";
              }
              {
                on = [
                  "z"
                  "l"
                ];
                run = "plugin time-travel next";
                desc = "Go to next snapshot";
              }
              {
                on = [
                  "z"
                  "e"
                ];
                run = "plugin time-travel exit";
                desc = "Exit browsing snapshots";
              }
            ];
        };
    };

    home = {
      packages = with pkgs; [
        unar
        exiftool
      ];
      shellAliases = {
        lf = "yazi";
        y = "yazi";
      };
    };
  }

  # smart-enter: enter for directory, open for file
  # https://yazi-rs.github.io/docs/tips/#smart-enter
  {
    programs.yazi = {
      plugins = mkYaziPlugin "smart-enter" ''
        --- @sync entry
        return {
        	entry = function()
            local h = cx.active.current.hovered
            ya.manager_emit(h and h.cha.is_dir and "enter" or "open", { hovered = true })
          end,
        }
      '';
      keymap.manager.prepend_keymap = [
        {
          on = "l";
          run = "plugin smart-enter";
          desc = "Enter the child directory, or open the file";
        }
      ];
    };
  }

  # smart-paste: paste files without entering the directory
  # https://yazi-rs.github.io/docs/tips/#smart-enter
  {
    programs.yazi = {
      plugins = mkYaziPlugin "smart-paste" ''
        --- @sync entry
        return {
          entry = function()
            local h = cx.active.current.hovered
            if h and h.cha.is_dir then
              ya.manager_emit("enter", {})
              ya.manager_emit("paste", {})
              ya.manager_emit("leave", {})
            else
              ya.manager_emit("paste", {})
            end
          end,
        }
      '';
      keymap.manager.prepend_keymap = [
        {
          on = "p";
          run = "plugin smart-paste";
          desc = "Paste into the hovered directory or CWD";
        }
      ];
    };
  }

  # arrow: file navigation wraparound
  {
    programs.yazi = {
      plugins = mkYaziPlugin "arrow" ''
        --- @sync entry
        return {
          entry = function(_, job)
            local current = cx.active.current
            local new = (current.cursor + job.args[1]) % #current.files
            ya.manager_emit("arrow", { new - current.cursor })
          end,
        }
      '';
      keymap.manager.prepend_keymap = [
        {
          on = "k";
          run = "plugin arrow -1";
        }
        {
          on = "j";
          run = "plugin arrow 1";
        }
      ];
    };
  }

  # folder specific rules?
  # https://yazi-rs.github.io/docs/tips/#folder-rules
]
