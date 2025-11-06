{
  inputs,
  lib,
  self,
  ...
}:

let
  inherit (lib) flatten mapAttrsToList stringToCharacters;

in

{
  flake.wrapperModules.yazi = inputs.wrappers.lib.wrapModule (
    { config, ... }:
    let
      sources = config.pkgs.callPackage ../../_sources/generated.nix { };
      mkYaziPlugin = name: text: {
        "${name}" = toString (config.pkgs.writeTextDir "${name}.yazi/main.lua" text) + "/${name}.yazi";
      };
      baseYaziConf = self.lib.recursiveMergeAttrsList [
        {
          plugins = {
            full-border = "${sources.yazi-plugins.src}/full-border.yazi";
            git = "${sources.yazi-plugins.src}/git.yazi";
          };

          initLua =
            config.pkgs.writeText "init.lua" # lua
              ''
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

            keymap = {
              mgr.prepend_keymap = [
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
                    ''shell -- ya emit cd "$(git rev-parse --show-toplevel)"'';
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
      # yazi option definitions copied from nixpkgs:
      # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/programs/yazi.nix
      options = {
        extraSettings = lib.mkOption {
          type =
            with lib.types;
            submodule {
              options = lib.listToAttrs (
                map
                  (
                    name:
                    lib.nameValuePair name (
                      lib.mkOption {
                        inherit (config.pkgs.formats.toml { }) type;
                        default = { };
                        description = ''
                          Configuration included in `${name}.toml`.

                          See <https://yazi-rs.github.io/docs/configuration/${name}/> for documentation.
                        '';
                      }
                    )
                  )
                  [
                    "yazi"
                    "theme"
                    "keymap"
                  ]
              );
            };
          default = { };
          description = ''
            Configuration included in `$YAZI_CONFIG_HOME`.
          '';
        };
      };

      config.package = config.pkgs.yazi.override {
        inherit (baseYaziConf) initLua plugins;
        extraPackages = with config.pkgs; [
          unar
          exiftool
        ];
        settings = self.lib.recursiveMergeAttrsList [
          baseYaziConf.settings
          config.extraSettings
        ];
      };
    }
  );

  perSystem =
    { pkgs, ... }:
    {
      packages.yazi' = (self.wrapperModules.yazi.apply { inherit pkgs; }).wrapper;
    };

  flake.nixosModules.core =
    {
      config,
      pkgs,
      dots,
      ...
    }:
    let
      yazi' =
        (self.wrapperModules.yazi.apply {
          inherit pkgs;
          extraSettings = {
            keymap =
              let
                homeDir = "/persist${config.hj.directory}";
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
              # add keymaps for shortcuts
              {
                mgr.prepend_keymap = flatten (
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
                );
              };
          };
        }).wrapper;
    in
    {
      # shell integrations
      programs = {
        bash.interactiveShellInit = # sh
          ''
            function yy() {
              local tmp="$(mktemp -t "yazi-cwd.XXXXX")"
              yazi "$@" --cwd-file="$tmp"
              if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
                builtin cd -- "$cwd"
              fi
              rm -f -- "$tmp"
            }
          '';

        fish.interactiveShellInit = # fish
          ''
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

      environment = {
        systemPackages = [ yazi' ];
        shellAliases = {
          lf = "yazi";
          y = "yazi";
        };
      };
    };
}
