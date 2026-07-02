{
  flake.modules.nixos.wm =
    { config, ... }:
    let
      inherit (config.custom.constants) dots projects;
      termExec = cmd: "ghostty -e ${cmd}";
    in
    {
      custom.programs.hyprland.settings = /* lua */ ''
        -- programs
        hl.bind(mod .. " + Return", hl.dsp.exec_cmd("ghostty"))
        hl.bind(mod .. " + SHIFT + Return", hl.dsp.exec_cmd("noctalia-ipc launcher toggle"))
        hl.bind(mod .. " + e", hl.dsp.exec_cmd("nemo ${config.hj.directory}/Downloads"))
        hl.bind(mod .. " + SHIFT + e", hl.dsp.exec_cmd("${termExec "yazi ${config.hj.directory}/Downloads"}"))
        hl.bind(mod .. " + w", hl.dsp.exec_cmd("helium --profile-directory=Default"))
        hl.bind(mod .. " + SHIFT + w", hl.dsp.exec_cmd("helium --profile-directory=Default --incognito"))
        hl.bind(mod .. " + v", hl.dsp.exec_cmd("emacsclient -c"))
        hl.bind(mod .. " + SHIFT + v", hl.dsp.exec_cmd("noctalia-ipc plugin:projects toggle"))
        hl.bind(
          mod .. " + period",
          hl.dsp.exec_cmd('focus-or-run "dotfiles - VSCodium" "codium ${dots}"')
        )
        hl.bind(
          mod .. " + SHIFT + period",
          hl.dsp.exec_cmd('focus-or-run "nixpkgs - VSCodium" "codium ${projects}/nixpkgs"')
        )

        -- noctalia bar
        hl.bind(mod .. " + a", hl.dsp.exec_cmd("noctalia-ipc bar toggle"))
        hl.bind(mod .. " + SHIFT + a", hl.dsp.exec_cmd("noctalia-reload"))

        -- clipboard history
        hl.bind(mod .. " + CTRL + v", hl.dsp.exec_cmd("noctalia-ipc launcher clipboard"))

        -- notification history
        hl.bind(mod .. " + n", hl.dsp.exec_cmd("noctalia-ipc notifications toggleHistory"))

        -- wallpaper
        hl.bind(mod .. " + apostrophe", hl.dsp.exec_cmd("wallpaper select"))
        hl.bind("ALT + apostrophe", hl.dsp.exec_cmd("wallpaper history"))

        -- reset monitors
        hl.bind("CTRL + SHIFT + Escape", hl.dsp.exec_cmd("hypr-monitors"))

        -- exit / reboot
        hl.bind("ALT + F4", hl.dsp.exit())
        hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("noctalia-ipc sessionMenu toggle"))

        -- moving between windows
        hl.bind(mod .. " + h", hl.dsp.focus({ direction = "l"}))
        hl.bind(mod .. " + l", hl.dsp.focus({ direction = "r"}))
        hl.bind(mod .. " + j", hl.dsp.focus({ direction = "u"}))
        hl.bind(mod .. " + k", hl.dsp.focus({ direction = "d"}))

        hl.bind(mod .. " + SHIFT + h", hl.dsp.window.move({ direction = "l" }))
        hl.bind(mod .. " + SHIFT + l", hl.dsp.window.move({ direction = "r" }))
        hl.bind(mod .. " + SHIFT + k", hl.dsp.window.move({ direction = "u" }))
        hl.bind(mod .. " + SHIFT + j", hl.dsp.window.move({ direction = "d" }))

        -- workspace switching / moving
        for i = 1, 10 do
          local key = i % 10 -- 10 maps to key 0
          hl.bind(mod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
          hl.bind(mod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
        end

        -- focus the previous / next workspace in the current monitor (DE style)
        hl.bind(mod .. " + Left", hl.dsp.focus({ workspace = "m-1" }))
        hl.bind(mod .. " + Right", hl.dsp.focus({ workspace = "m+1" }))

        -- window management
        hl.bind(mod .. " + BackSpace", hl.dsp.window.close(), { repeating = false })
        hl.bind(mod .. " + z", hl.dsp.window.fullscreen({ type = "maximize" })) -- monocle
        hl.bind(mod .. " + f", hl.dsp.window.fullscreen({ type = "fullscreen" })) -- fullscreen
        hl.bind(mod .. " + SHIFT + f", hl.dsp.window.fullscreen_state({ client = -1, internal = 2 })) -- fakefullscreen
        hl.bind(mod .. " + g", hl.dsp.window.float({ action = "toggle" }))
        hl.bind(mod .. " + s", hl.dsp.window.pin())
        hl.bind(mod .. " + grave", hl.dsp.focus({ last = true }))

        -- cycle windows (classic alt tab in a workspace)
        hl.bind("ALT + Tab", hl.dsp.window.cycle_next({ next = true }))
        hl.bind("ALT + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }))

        -- cycle between windows of the same class
        hl.bind("CTRL + ALT + Tab", hl.dsp.exec_cmd("wm-same-class next"))
        hl.bind("CTRL + ALT + SHIFT + Tab", hl.dsp.exec_cmd("wm-same-class prev"))

        -- picture in picture mode
        hl.bind(mod .. " + p", hl.dsp.exec_cmd("wm-pip"))

        -- monitor focus / move to monitor
        hl.bind(mod .. " + Tab", hl.dsp.focus({ monitor = "+1" }))
        hl.bind(mod .. " + SHIFT + Tab", hl.dsp.window.move({ monitor = "+1" }))

        -- master layout
        hl.bind(mod .. " + b", hl.dsp.layout("swapwithmaster"))
        hl.bind(mod .. " + m", hl.dsp.layout("addmaster"))
        hl.bind(mod .. " + SHIFT + m", hl.dsp.layout("removemaster"))

        -- move/resize windows with mouse
        hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
        hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

        -- scroll workspaces with mouse wheel
        hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
        hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

        -- audio
        hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer -d 5"), { locked = true })
        hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer -i 5"), { locked = true })
        hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pamixer -t"), { locked = true })
      '';
    };
}
