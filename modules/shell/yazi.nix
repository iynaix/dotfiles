{
  inputs,
  self,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    let
      baseYaziConf = self.libCustom.recursiveMergeAttrsList [
        {
          plugins = { inherit (pkgs.yaziPlugins) full-border git; };

          constructFiles = {
            init = {
              relPath = "yazi-config/init.lua";
              content = /* lua */ ''
                require("full-border"):setup({ type = ui.Border.ROUNDED })
                require("git"):setup()
              '';
            };
          };

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
          plugins.time-travel = pkgs.fetchFromGitHub {
            owner = "iynaix";
            repo = "time-travel.yazi";
            rev = "aaec6e26e525bd146354a5137ec40f1f23257a4e";
            hash = "sha256-/+KiuGUox763dMQvHl1l3+Ci3vL8NwRuKNu9pi3gjyE=";
          };

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
        {
          plugins = { inherit (pkgs.yaziPlugins) smart-enter; };
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
        {
          plugins = { inherit (pkgs.yaziPlugins) smart-paste; };
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
      ];
    in
    {
      packages.yazi = inputs.wrappers.wrappers.yazi.wrap (
        baseYaziConf
        // {
          inherit pkgs;
          runtimePkgs = with pkgs; [
            unar
            exiftool
          ];
        }
      );
    };

  flake.modules.nixos.core =
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

      nixpkgs.overlays = [
        (_: _prev: {
          # set dynamic flavor from noctalia
          yazi = pkgs.custom.yazi.wrap {
            settings = {
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
        let
          yaziDir = dirOf pkgs.yazi.configuration.constructFiles.yazi;
        in
        {
          yazi = /* sh */ ''cat "${yaziDir}/yazi.toml" "${yaziDir}/theme.toml" "${yaziDir}/keymap.toml" | moor --lang toml'';
        };
    };
}
