{
  config,
  lib,
  libCustom,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  # setup wallust colorschemes for shells
  programs = {
    bash.shellInit = mkIf config.hm.custom.wallust.enable ''
      wallust_colors="${libCustom.xdgCachePath "wallust/sequences"}"
      if [ -e "$wallust_colors" ]; then
        command cat "$wallust_colors"
      fi
    '';

    fish.shellInit = mkIf config.hm.custom.wallust.enable ''
      set wallust_colors "${libCustom.xdgCachePath "wallust/sequences"}"
      if test -e "$wallust_colors"
          command cat "$wallust_colors"
      end
    '';
  };
}
