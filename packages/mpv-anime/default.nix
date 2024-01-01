{
  lib,
  stdenvNoCC,
  fetchgit,
  fetchurl,
  p7zip,
  source,
}: let
  fsrcnnx_version = "1.1";
in
  stdenvNoCC.mkDerivation (
    # source is RAVU
    source
    // {
      pname = "mpv-anime";
      version = "0.1.0";

      # SSimSuperRes
      ssimsuperres = fetchgit {
        url = "https://gist.githubusercontent.com/igv/2364ffa6e81540f29cb7ab4c9bc05b6b";
        rev = "15d93440d0a24fc4b8770070be6a9fa2af6f200b";
        sha256 = "sha256-aivMV1UypnkkdmFhurxVYBp76VlY8S29hQN4EEnJRPY=";
      };

      # FSRCNNX
      fsrcnnx_16 = fetchurl {
        url = "https://github.com/igv/FSRCNN-TensorFlow/releases/download/${fsrcnnx_version}/FSRCNNX_x2_16-0-4-1.glsl";
        sha256 = "sha256-1aJKJx5dmj9/egU7FQxGCkTCWzz393CFfVfMOi4cmWU=";
      };

      fsrcnnx_8 = fetchurl {
        url = "https://github.com/igv/FSRCNN-TensorFlow/releases/download/${fsrcnnx_version}/FSRCNNX_x2_8-0-4-1.glsl";
        sha256 = "sha256-6ADbxcHJUYXMgiFsWXckUz/18ogBefJW7vYA8D6Nwq4=";
      };

      fsrcnnx_8_lineart = fetchurl {
        url = "https://github.com/igv/FSRCNN-TensorFlow/releases/download/${fsrcnnx_version}/checkpoints_params.7z";
        sha256 = "sha256-h5B7DU0W5B39rGaqC9pEqgTTza5dKvUHTFlEZM1mfqo=";
      };

      nativeBuildInputs = [p7zip];

      unpackPhase = ''
        mkdir -p $TMP
        7z x $fsrcnnx_8_lineart -o$TMP
      '';

      installPhase = ''
        runHook preInstall

        mkdir -p $out

        cp -r $src/* $out
        cp $fsrcnnx_16 $out/FSRCNNX_x2_16-0-4-1.glsl
        cp $fsrcnnx_8 $out/FSRCNNX_x2_8-0-4-1.glsl
        cp $ssimsuperres/* $out
        cp $TMP/FSRCNNX_x2_8-0-4-1_LineArt.glsl $out/FSRCNNX_x2_8-0-4-1_LineArt.glsl

        runHook postInstall
      '';

      passthru.scriptName = "sub-select.lua";

      meta = {
        description = "Various packages for anime within mpv";
        maintainers = [lib.maintainers.iynaix];
      };
    }
  )
