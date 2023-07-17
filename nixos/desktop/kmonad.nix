{
  lib,
  config,
  ...
}: let
  cfg = config.iynaix.kmonad;
in {
  options.iynaix.kmonad = {
    enable = lib.mkEnableOption "kmonad";
  };

  config = lib.mkIf cfg.enable {
    services.kmonad = {
      enable = true;

      keyboards.laptop = {
        device = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";
        defcfg = {
          enable = true;
          fallthrough = true;
        };

        config = ''
          (defsrc
            esc  f1   f2   f3   f4   f5   f6   f7   f8   f9   f10  f11  f12  ssrq ins  del
            grv  1    2    3    4    5    6    7    8    9    0    -    =    bspc
            tab  q    w    e    r    t    y    u    i    o    p    [    ]    \
            caps a    s    d    f    g    h    j    k    l    ;    '    ret
            lsft z    x    c    v    b    n    m    ,    .    /    rsft up
            lctl lmet lalt           spc            ralt rctl left down rght
          )

          (defalias
            superesc (tap-next-release esc met)
            copy C-c
            paste C-v
            save C-s
          )

          (deflayer mylayer
            esc  f1   f2   f3   f4   f5   f6   f7   f8   f9   f10  f11  f12  ssrq ins  del
            grv  1    2    3    4    5    6    7    8    9    0    -    =    bspc
            tab  q    w    e    r    t    y    u    i    o    p    [    ]    \
            @superesc a    s    d    f    g    h    j    k    l    ;    '    ret
            lsft z    x    c    v    b    n    m    ,    .    /    @save up
            lctl lmet lalt           spc            @copy @paste left down rght
          )
        '';
      };
    };
  };
}
