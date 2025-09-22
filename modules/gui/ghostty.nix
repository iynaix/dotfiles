{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) assertMsg getExe versionOlder;
  # adapted from home-manager:
  # https://github.com/nix-community/home-manager/blob/master/modules/programs/ghostty.nix
  toGhosttyConf =
    (pkgs.formats.keyValue {
      listsAsDuplicateKeys = true;
      mkKeyValue = lib.generators.mkKeyValueDefault { } " = ";
    }).generate
      "ghostty-config";

  padding = 12;
  fishPath = getExe config.hm.programs.fish.package;

  ghosttyConf = {
    alpha-blending = "linear-corrected";
    background-opacity =
      0.85
      # more opaque on niri as there is no blur
      + (if (config.hm.custom.wm == "niri" && !config.hm.custom.niri.blur.enable) then 0.1 else 0);
    # set as default interactive shell, also set $SHELL for nix shell to pick up
    command = "SHELL=${fishPath} ${fishPath}";
    confirm-close-surface = false;
    copy-on-select = "clipboard";
    # disable clipboard copy notifications temporarily until fixed upstream
    # https://github.com/ghostty-org/ghostty/issues/4800#issuecomment-2685774252
    app-notifications =
      assert (
        assertMsg (versionOlder pkgs.ghostty.version "1.2.0") "ghostty: re-enable clipboard copy notifications"
      );
      "no-clipboard-copy";
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
