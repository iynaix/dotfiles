{ lib, self, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      sources = self.libCustom.nvFetcherSources pkgs;
      mkYaziPlugin = name: text: {
        "${name}" = toString (pkgs.writeTextDir "${name}.yazi/main.lua" text) + "/${name}.yazi";
      };
      baseYaziConf = self.libCustom.recursiveMergeAttrsList [
        {
          plugins = {
            full-border = "${sources.yazi-plugins.src}/full-border.yazi";
            git = "${sources.yazi-plugins.src}/git.yazi";
          };

          initLua = pkgs.writeText "init.lua" /* lua */ ''
            require("full-border"):setup({ type = ui.Border.ROUNDED })
            require("git"):setup()
          '';

          settings = {
            yazi = {
              log = {
                enabled = true;
              };
              mgr = {
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
              mgr = {
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

              indicator = {
                padding = {
                  open = "█";
                  close = "█";
                };
                preview = {
                  underline = false;
                };
              };

              status = {
                sep_left = {
                  open = "";
                  close = "";
                };
                sep_right = {
                  open = "";
                  close = "";
                };
              };

            };

            keymap = {
              mgr.prepend_keymap = [
                # dropping to shell
                {
                  on = "!";
                  run = /* sh */ ''shell "$SHELL" --block --confirm'';
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
                  run = /* sh */ ''shell -- ya emit cd "$(git rev-parse --show-toplevel)"'';
                  desc = "Cd to root of current git repo";
                }
              ];
            };
          };
        }

        # browsing forwards and backwards in time through snapshots
        # https://github.com/iynaix/time-travel.yazi
        {
          plugins.time-travel = sources.yazi-time-travel.src;
          settings = {
            keymap.mgr.prepend_keymap = [
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
        }

        # smart-enter: enter for directory, open for file
        # https://yazi-rs.github.io/docs/tips/#smart-enter
        {
          plugins = mkYaziPlugin "smart-enter" ''
            --- @sync entry
            return {
            	entry = function()
                local h = cx.active.current.hovered
                ya.manager_emit(h and h.cha.is_dir and "enter" or "open", { hovered = true })
              end,
            }
          '';
          settings = {
            keymap.mgr.prepend_keymap = [
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
          settings = {
            keymap.mgr.prepend_keymap = [
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
          settings = {
            keymap.mgr.prepend_keymap = [
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
      ];
    in
    {
      packages.yazi' =
        (pkgs.yazi.override {
          inherit (baseYaziConf) initLua plugins settings;
          extraPackages = with pkgs; [
            unar
            exiftool
          ];
        }).overrideAttrs
          {
            passthru = {
              inherit (baseYaziConf) settings;
            };
          };
    };

  flake.nixosModules.core =
    { config, pkgs, ... }:
    {
      # shell integrations
      programs = {
        bash.interactiveShellInit = /* sh */ ''
          function yy() {
            local tmp="$(mktemp -t "yazi-cwd.XXXXX")"
            yazi "$@" --cwd-file="$tmp"
            if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
              builtin cd -- "$cwd"
            fi
            rm -f -- "$tmp"
          }
        '';

        fish.interactiveShellInit = /* fish */ ''
          function yy
            set -l tmp (mktemp -t "yazi-cwd.XXXXX")
            command yazi $argv --cwd-file="$tmp"
            if set cwd (cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
              builtin cd -- "$cwd"
            end
            rm -f -- "$tmp"
          end
        '';
      };

      nixpkgs.overlays =
        let
          inherit (self.packages.${pkgs.stdenv.hostPlatform.system}) yazi';
        in
        [
          (_: _prev: {
            # set dynamic flavor from noctalia
            yazi = yazi'.override {
              settings = lib.recursiveUpdate yazi'.passthru.settings {
                theme.flavor = {
                  dark = "noctalia";
                  light = "noctalia";
                };
              };

              flavors = {
                noctalia = "${config.hj.xdg.config.directory}/yazi/flavors/noctalia.yazi";
              };
            };
          })
        ];

      environment = {
        systemPackages = [
          pkgs.yazi # overlay-ed above
        ];

        shellAliases = {
          lf = "yazi";
          y = "yazi";
        };
      };

      custom.programs.print-config =
        # yazi uses makeWrapper directly, no choice but to parse the wrapper
        let
          catYaziPath = path: /* sh */ ''
            YAZI_PATH=$(grep "export YAZI_CONFIG_HOME=" '${lib.getExe pkgs.yazi}' | cut -d"'" -f2)

            cat "$YAZI_PATH/${path}"
          '';
        in
        {
          yazi = catYaziPath "yazi.toml";
          yazi-theme = catYaziPath "theme.toml";
          yazi-keymap = catYaziPath "keymap.toml";
        };
    };
}
