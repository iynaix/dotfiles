{ tela-icon-theme }:
tela-icon-theme.overrideAttrs (oldAttrs: {
  postPatch =
    (oldAttrs.postPatch or "")
    + ''
      cp ${./install.sh} install.sh
    '';
})
