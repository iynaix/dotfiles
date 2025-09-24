{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe;
  # adapted from home-manager:
  # https://github.com/nix-community/home-manager/blob/master/modules/programs/ghostty.nix
  toGhosttyConf =
    (pkgs.formats.keyValue {
      listsAsDuplicateKeys = true;
      mkKeyValue = lib.generators.mkKeyValueDefault { } " = ";
    }).generate
      "ghostty-config";

  padding = 12;
  fishPath = getExe pkgs.fish;

  ghosttyConf = {
    alpha-blending = "linear-corrected";
    app-notifications = "no-clipboard-copy";
    background-opacity =
      0.85
      # more opaque on niri as there is no blur
      + (if (config.custom.wm == "niri" && !config.hm.custom.niri.blur.enable) then 0.1 else 0);
    # set as default interactive shell, also set $SHELL for nix shell to pick up
    command = "SHELL=${fishPath} ${fishPath}";
    confirm-close-surface = false;
    copy-on-select = "clipboard";
    cursor-style = "bar";
    font-family = config.hm.custom.fonts.monospace;
    font-feature = "zero";
    font-size = 10;
    font-style = "Medium";
    window-decoration = false;
    window-padding-x = padding;
    window-padding-y = padding;
  };
in
{
  custom.wrappers = [
    (
      { pkgs, ... }:
      {
        wrappers.ghostty = {
          basePackage = pkgs.ghostty;
          prependFlags = [
            "--config-default-files=false"
            # NOTE: don't use wrapWithRuntimeConfig as ghostty "helpfully" creates an empty config in the
            # default location
            "--config-file=${toGhosttyConf ghosttyConf}"
          ];
        };
      }
    )
  ];

  environment.systemPackages = [ pkgs.ghostty ];

  hm.custom.terminal = {
    app-id = "com.mitchellh.ghostty";
    desktop = "com.mitchellh.ghostty.desktop";
  };
}
