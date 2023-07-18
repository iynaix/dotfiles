{...}: {
  config = {
    xdg.mime.defaultApplications = {
      "image/jpeg" = "imv-dir.desktop";
      "image/gif" = "imv-dir.desktop";
      "image/webp" = "imv-dir.desktop";
      "image/png" = "imv-dir.desktop";
    };

    nixpkgs.overlays = [
      (self: super: {
        # patch imv to not repeat keypresses causing waybar to launch infinitely
        # https://github.com/eXeC64/imv/issues/207#issuecomment-604076888
        imv = super.imv.overrideAttrs (oldAttrs: {
          patches = [./imv-disable-key-repeat-timer.patch];
        });
      })
    ];
  };
}
