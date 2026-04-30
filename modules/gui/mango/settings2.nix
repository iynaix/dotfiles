# additional settings for mango
{
  flake.modules.nixos.wm = {
    custom.programs = {
      # More option see https://github.com/DreamMaoMao/mango/wiki/
      mango.settings = {
        # Window effect
        border_radius = 6;
        no_radius_when_single = 0;
        focused_opacity = 1.0;
        unfocused_opacity = 1.0;

        # Animation Configuration
        animations = 1;
        layer_animations = 0;
        animation_type_open = "slide";
        animation_type_close = "slide";
        animation_fade_in = 1;
        animation_fade_out = 1;
        tag_animation_direction = 1;
        zoom_initial_ratio = 0.3;
        zoom_end_ratio = 0.8;
        fadein_begin_opacity = 0.5;
        fadeout_begin_opacity = 0.8;
        animation_duration_move = 500;
        animation_duration_open = 400;
        animation_duration_tag = 350;
        animation_duration_close = 800;
        animation_curve_open = "0.46,1.0,0.29,1";
        animation_curve_move = "0.46,1.0,0.29,1";
        animation_curve_tag = "0.46,1.0,0.29,1";
        animation_curve_close = "0.08,0.92,0,1";

        # Scroller Layout Setting
        scroller_structs = 20;
        scroller_default_proportion = 0.8;
        scroller_focus_center = 0;
        scroller_prefer_center = 0;
        scroller_default_proportion_single = 1.0;
        scroller_proportion_preset = "0.5,0.8,1.0";

        # Master-Stack Layout Setting
        new_is_master = 0;
        default_mfact = 0.55;
        default_nmaster = 1;
        smartgaps = 0;

        # Overview Setting
        hotarea_size = 10;
        enable_hotarea = 1;
        ov_tab_mode = 0;
        overviewgappi = 5;
        overviewgappo = 30;

        # Misc
        no_border_when_single = 0;
        axis_bind_apply_timeout = 100;
        focus_on_activate = 1;
        idleinhibit_ignore_visible = 0;
        sloppyfocus = 1;
        warpcursor = 1;
        focus_cross_monitor = 0;
        focus_cross_tag = 0;
        enable_floating_snap = 0;
        snap_distance = 30;
        cursor_size = 24;
        drag_tile_to_tile = 1;

        # Keyboard
        repeat_rate = 25;
        repeat_delay = 600;
        numlockon = 1;
        xkb_rules_layout = "us";

        # Trackpad
        disable_trackpad = 0;
        tap_to_click = 1;
        tap_and_drag = 1;
        drag_lock = 1;
        trackpad_natural_scrolling = 0;
        disable_while_typing = 1;
        left_handed = 0;
        middle_button_emulation = 0;
        swipe_min_threshold = 20;

        # Mouse
        mouse_natural_scrolling = 0;

        # Appearance
        gappih = 5;
        gappiv = 5;
        gappoh = 10;
        gappov = 10;
        scratchpad_width_ratio = 0.8;
        scratchpad_height_ratio = 0.9;
        borderpx = 4;
        rootcolor = "0x201b14ff";
        bordercolor = "0x444444ff";
        focuscolor = "0xc9b890ff";
        maximizescreencolor = "0x89aa61ff";
        urgentcolor = "0xad401fff";
        scratchpadcolor = "0x516c93ff";
        globalcolor = "0xb153a7ff";
        overlaycolor = "0x14a57cff";

        # Key Bindings
        bind = [
          "$mod, r, reload_config"
          "$mod, Tab, focusstack, next"
          "ALT, Left, focusdir, left"
          "ALT, Right, focusdir, right"
          "ALT, Up, focusdir, up"
          "ALT, Down, focusdir, down"
          "$mod+SHIFT, Up, exchange_client, up"
          "$mod+SHIFT, Down, exchange_client, down"
          "$mod+SHIFT, Left, exchange_client, left"
          "$mod+SHIFT, Right, exchange_client, right"
          "ALT, a, togglemaximizescreen, "
          "ALT+SHIFT, f, togglefakefullscreen, "
          "$mod, i, minimized, "
          "$mod+SHIFT, I, restore_minimized"
          "ALT, e, set_proportion, 1.0"
          "ALT, x, switch_proportion_preset, "
          "$mod, Left, viewtoleft, "
          "CTRL, Left, viewtoleft_have_client, "
          "$mod, Right, viewtoright, "
          "CTRL, Right, viewtoright_have_client, "
          "CTRL+$mod, Left, tagtoleft, "
          "CTRL+$mod, Right, tagtoright, "
          "ALT+SHIFT, Left, focusmon, left"
          "ALT+SHIFT, Right, focusmon, right"
          "$mod+ALT, Left, tagmon, left"
          "$mod+ALT, Right, tagmon, right"
          "CTRL+SHIFT, Up, movewin, +0, -50"
          "CTRL+SHIFT, Down, movewin, +0, +50"
          "CTRL+SHIFT, Left, movewin, -50, +0"
          "CTRL+SHIFT, Right, movewin, +50, +0"
          "CTRL+ALT, Up, resizewin, +0, -50"
          "CTRL+ALT, Down, resizewin, +0, +50"
          "CTRL+ALT, Left, resizewin, -50, +0"
          "CTRL+ALT, Right, resizewin, +50, +0"
        ];

        # Mouse Button Bindings
        mousebind = [
          "$mod, btn_left, moveresize, curmove"
          "$mod, btn_right, moveresize, curresize"
        ];
      };
    };
  };
}
