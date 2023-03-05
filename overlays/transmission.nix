# transmission dark mode, the default theme is hideous
self: super: {
  transmission = super.transmission.overrideAttrs (old: rec {
    themeSrc = super.fetchzip
      {
        url = "https://git.eigenlab.org/sbiego/transmission-web-soft-theme/-/archive/master/transmission-web-soft-theme-master.tar.gz";
        sha256 = "sha256-TAelzMJ8iFUhql2CX8lhysXKvYtH+cL6BCyMcpMaS9Q=";
      };
    # sed command taken from original install.sh script
    postInstall = ''
      ${old.postInstall}
      cp -RT ${themeSrc}/web/ $out/share/transmission/web/
      sed -i '21i\\t\t<link href="./style/transmission/soft-theme.min.css" type="text/css" rel="stylesheet" />\n\t\t<link href="style/transmission/soft-dark-theme.min.css" type="text/css" rel="stylesheet" />\n' $out/share/transmission/web/index.html;
    '';
  });
}
