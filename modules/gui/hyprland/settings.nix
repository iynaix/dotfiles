{ lib, self, ... }:
{
  flake.modules.nixos.wm =
    { config, ... }:
    let
      toLua = lib.generators.toLua { };
      inherit (config.custom.constants) host isVm;
      hasHdr = lib.any (d: d.hdr) config.custom.hardware.monitors;
      gap = if host == "desktop" then 8 else 4;
      strut = gap + 12;
    in
    {
      custom.programs.hyprland = {
        luaText = lib.mkMerge [
          # define variables at top of file
          (lib.mkBefore /* lua */ ''
            local mod = "${if isVm then "ALT" else "SUPER"}"
          '')

          /* lua */
          ''
            hl.config({
            	animations = {
            		enabled = ${lib.boolToString (!isVm)},
            	},

            	binds = {
            		workspace_back_and_forth = true,
            	},

            	debug = {
            		disable_logs = false,
            	},

            	decoration = {
            		rounding = 4,
            		blur = {
                  enabled = ${lib.boolToString (!isVm)},
            			new_optimizations = true,
            			passes = 3,
            			size = 2,
            		},
            		shadow = {
                  enabled = ${lib.boolToString (!isVm)},
            			color = "rgba(1a1a1aee)",
            			range = 4,
            			render_power = 3,
            		},
            	},

            	dwindle = {
            		preserve_split = true,
            	},

            	ecosystem = {
            		no_donation_nag = true,
            		no_update_news = true,
            	},

            	general = {
            		border_size = 2,
            		gaps_in = 4,
            		gaps_out = { top = ${toString gap}, right = ${toString strut}, bottom = ${toString gap}, left = ${toString strut} },
            		layout = "scrolling",
            	},

            	input = {
            		follow_mouse = 1,
            		kb_layout = "us",
            		touchpad = {
            			disable_while_typing = true,
            			natural_scroll = false,
            		},
            	},

            	master = {
            		mfact = 0.5,
            		new_on_active = "after",
            		orientation = "left",
            		smart_resizing = true,
            	},

            	misc = {
            		disable_hyprland_logo = true,
            		disable_splash_rendering = true,
            		enable_swallow = false,
            		initial_workspace_tracking = 0,
            		mouse_move_enables_dpms = true,
            		swallow_regex = "^([Kk]itty|[Ww]ezterm|[Gg]hostty)$",
            	},

            	render = {
            		cm_enabled = ${lib.boolToString hasHdr},
            		cm_auto_hdr = 2,
            	},

            	scrolling = {
            		fullscreen_on_one_column = true,
            	},
            })

            -- 3 finger swipe to switch workspace
            hl.gesture({
              fingers = 3,
              direction = "horizontal",
              action = "workspace"
            })

            -- thicker border in monocle mode
            hl.window_rule({ match = { fullscreen = true }, border_size = 5 })
            -- save dialogs
            hl.window_rule({ match = { class = "xdg-desktop-portal-gtk" }, float = true, size = "<50% <50%" })

            -- custom curves
            hl.curve("overshot", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
            hl.curve("smoothOut", { type = "bezier", points = { { 0.36, 0 }, { 0.66, -0.56 } } })
            hl.curve("smoothIn", { type = "bezier", points = { { 0.25, 1 }, { 0.5, 1 } } })

            -- custom animations
            hl.animation({ enabled = true, leaf = "windows", speed = 5, bezier = "overshot", style = "slide" })
            hl.animation({ enabled = true, leaf = "windowsOut", speed = 4, bezier = "smoothOut", style = "slide" })
            hl.animation({ enabled = true, leaf = "windowsMove", speed = 4, bezier = "smoothIn", style = "slide" })
            hl.animation({ enabled = true, leaf = "layers", speed = 5, bezier = "default", style = "popin 80%" })
            hl.animation({ enabled = true, leaf = "border", speed = 5, bezier = "default" })
            hl.animation({ enabled = true, leaf = "borderangle", speed = 100, bezier = "default", style = "loop" })
            hl.animation({ enabled = true, leaf = "fade", speed = 5, bezier = "smoothIn" })
            hl.animation({ enabled = true, leaf = "fadeDim", speed = 5, bezier = "smoothIn" })
            hl.animation({ enabled = true, leaf = "workspaces", speed = 6, bezier = "default", style = "slidevert" })

            -- fallback monitor settings
            hl.monitor({
                output   = "",
                mode     = "preferred",
                position = "auto",
                scale    = "auto",
            })
          ''

          # monitor settings
          (
            config.custom.hardware.monitors
            |> map (
              d:
              {
                output = d.name;
                mode = "${toString d.width}x${toString d.height}@${toString d.refreshRate}";
                position = "${toString d.x}x${toString d.y}";
                inherit (d) scale transform vrr;
              }
              // (lib.optionalAttrs d.hdr {
                bitdepth = 10;
                cm = "auto";
              })
            )
            |> lib.concatMapStringsSep "\n" (params: "hl.monitor(${toLua params})")
          )

          # workspace rules
          (
            config.custom.hardware.monitors
            |> self.libCustom.mapWorkspaces (
              { monitor, workspace, ... }:
              {
                inherit workspace;
                persistent = true;
                layout_opts.direction = if monitor.isVertical then "down" else "right";
              }
              # bind workspace to monitors, don't bother if there is only one monitor
              // lib.optionalAttrs (lib.length config.custom.hardware.monitors > 1) {
                "monitor" = monitor.name;
              }
              // lib.optionalAttrs (workspace == toString monitor.defaultWorkspace) { default = true; }
            )
            |> lib.concatMapStringsSep "\n" (params: "hl.workspace_rule(${toLua params})")
          )

          # include noctalia colors if available
          (lib.mkAfter /* lua */ ''
            local p = os.getenv("HOME") .. "/.config/hypr/noctalia/noctalia-colors.lua"
            if io.open(p, "r") then dofile(p) end
          '')
        ];
      };
    };
}
