{
  pkgs,
  user,
  ...
}: let
  renameutils = pkgs.renameutils.overrideAttrs (oldAttrs: {
    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [pkgs.makeWrapper];

    # fix name conflict with imv imageviewer
    postInstall = ''
      mv $out/bin/imv $out/bin/imv2
      mv $out/share/man/man1/imv.1 $out/share/man/man1/imv2.1
    '';

    postFixup = ''
      # fix invoking nvim without plugins
      wrapProgram $out/bin/qmv --add-flags "--editor nvim"
    '';
  });
in {
  config = {
    home-manager.users.${user} = {
      home.packages = [renameutils];
    };
  };
}
