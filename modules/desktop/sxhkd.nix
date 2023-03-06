{ pkgs, host, user, config, ... }:
# use alt in vms to avoid conflicts with the host
let mod = if host == "vm" then "alt" else "super"; in
{
  home-manager.users.${user} = {
    services = {
      sxhkd = {
        enable = true;
        keybindings = {
          # terminal emulator
          "${mod} + Return" = "$TERMINAL";

          # program launcher
          "${mod} + shift + Return" = "rofi -show drun";

          # rofi shutdown actions menu
          "ctrl + alt + Delete" = ''
            rofi -show power-menu -font "${config.iynaix.font.regular} 14" -modi power-menu:rofi-power-menu'';

          # screenshots
          "${mod} + shift + backslash" = "rofi-screenshot";

          # browser
          "${mod} + {_, shift + }w" = "brave {_,--incognito}";
          "${mod} + {_, shift + }v" = "{$TERMINAL -e nvim,code}";

          # clipboard via clipmenu
          "${mod} + ctrl + v" = "clipmenu";

          # file browser
          "${mod} + {_, shift + }e" =
            "{nemo ~/Downloads,$TERMINAL -e ranger ~/Downloads}";

          # special keys
          "XF86AudioPlay" = "mpvctl playpause";

          # BSPWM KEYBINDINGS

          # reload bspwm
          "ctrl + shift + Escape" =
            "pkill -USR1 -x sxhkd & ~/.config/bspwm/bspwmrc";

          # close and kill
          "${mod} + BackSpace" = "bspc node -c";

          # alternate between the tiled and monocle layout
          "${mod} + z" = "bspc desktop -l next";

          # send the newest marked node to the newest preselected node
          "${mod} + y" =
            "bspc node newest.marked.local -n newest.!automatic.local";

          # swap the current node and the biggest node
          "${mod} + b" = "bspc node -s biggest.local";

          # equalize size of windows at parent / root level
          "${mod} + {_,ctrl + }equal" = "bspc node {@parent,@/} --balance";

          # set the window state
          "${mod} + {space,f}" = "bspc node -t '~{floating,fullscreen}'";

          # set the node flags
          "${mod} + ctrl + {m,y}" = "bspc node -g {marked,sticky}";

          # picture in picture mode
          "${mod} + shift + p" = "bspc-pip";

          # focus the node in the given direction
          "${mod} + {_,shift + }{h,j,k,l}" =
            "bspc node -f {_,-s} {west,south,north,east}";

          # focus the node in the given direction, handles wraparound for monitors
          # ${mod} + {h,l}
          #     {WINDOW=left;DESKTOP=prev;,WINDOW=right;DESKTOP=next;} \
          #     if ! bspc window -f $WINDOW; then \
          #         bspc desktop -f $DESKTOP; \
          #     fi

          # focus the node for the given path jump
          # ${mod} + {p,b,comma,period}
          # 	bspc node -f @{parent,brother,first,second}

          # focus the next/previous node in the current desktop
          # "alt + {_,shift + }Tab" = "bspc node -f {next,prev}.local";

          # focus the next/previous node of the same class
          "${mod} + {_,shift + }Tab" = "bspc node -f {next,prev}.same_class";

          # focus the previous / next monitor
          "${mod} + bracket{left,right}" = "bspc monitor -f {prev,next}";

          # move to the previous / next monitor, retains node focus
          "${mod} + shift + bracket{left,right}" =
            "bspc node -m {prev,next} --follow";

          # focus the previous / next desktop in the current monitor (DE style)
          "ctrl + alt + {Left,Right}" = "bspc desktop -f {prev,next}.local";

          # focus the last node/desktop
          # ${mod} + {grave,Tab}
          # 	bspc {node,desktop} -f last
          "${mod} + grave" = "bspc node -f last";

          # focus the older or newer node in the focus history
          "${mod} + {o,i}" = ''
            bspc wm -h off; \
            	bspc node {older,newer} -f; \
            	bspc wm -h on'';

          # focus given desktop, also does i3 inspired workspace back and forth
          "${mod} + {1-9,0}" = ''
            desktop='{1-9,10}'; \
            	bspc query -D -d "$desktop.focused" && bspc desktop -f last.local || bspc desktop -f "$desktop"'';

          # send to given desktop, retains node focus
          "${mod} + shift + {1-9,0}" = "bspc node -d '{1-9,10}' --follow";

          # rotate parent / root
          "${mod} + {_, ctrl + }{_,shift + }r" =
            "bspc node {@parent,@/} -R {90,270}";

          # preselect the direction
          # ${mod} + ctrl + {h,j,k,l}
          # 	bspc node -p {west,south,north,east}

          # preselect the ratio
          # ${mod} + ctrl + {1-9}
          # 	bspc node -o 0.{1-9}

          # cancel the preselection for the focused node
          # ${mod} + Escape
          # 	bspc node -p cancel

          # expand a window by moving one of its side outward
          "${mod} + alt + {h,j,k,l}" =
            "bspc node -z {left -20 0,bottom 0 20,top 0 -20,right 20 0}";

          # contract a window by moving one of its side inward
          "${mod} + alt + shift + {h,j,k,l}" =
            "bspc node -z {right -20 0,top 0 20,bottom 0 -20,left 20 0}";

          # move a floating window / pip window
          "${mod} + {Left,Down,Up,Right}" = "bspc-smartmove {left,down,up,right}";

          # toggle default gaps / gapless
          "${mod} + shift + slash" = ''
            curr_gap=$(bspc config window_gap); \
                if [ $curr_gap -eq 0 ]; then; \
                    window_gap=10; \
                    bar_height=30; \
                    padding=10; \
                    bspc config window_gap $window_gap; \
                    bspc config left_padding $padding; \
                    bspc config right_padding $padding; \
                    bspc config bottom_padding $padding; \
                    bspc config top_padding $((padding + bar_height)); \
                else; \
                    bar_height=30; \
                    bspc config window_gap 0; \
                    bspc config left_padding 0; \
                    bspc config right_padding 0; \
                    bspc config bottom_padding 0; \
                    bspc config top_padding $bar_height; \
                fi'';
        };
      };
    };
  };
}
