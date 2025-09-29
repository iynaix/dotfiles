{ lib, pkgs, ... }:
# anime profile settings
let
  inherit (lib)
    concatMapStringsSep
    hasSuffix
    imap
    listToAttrs
    ;
  shaders_dir = "${pkgs.mpv-shim-default-shaders}/share/mpv-shim-default-shaders/shaders";
  shaderList =
    shaders:
    concatMapStringsSep ":"
      (s: if (hasSuffix ".hook" s) then "${shaders_dir}/${s}" else "${shaders_dir}/${s}.glsl")
      (
        # Adds a very small amount of static noise to help with debanding.
        [
          "noise_static_luma.hook"
          "noise_static_chroma.hook"
        ]
        ++ shaders
      );
  anime4k_shaders = map (s: "Anime4K_" + s) [
    "Clamp_Highlights"
    "Restore_CNN_VL"
    "Upscale_CNN_x2_VL"
    "AutoDownscalePre_x2"
    "AutoDownscalePre_x4"
    "Upscale_CNN_x2_M"
  ];
  createShaderKeybind =
    shaders: description:
    ''no-osd change-list glsl-shaders set "${shaderList shaders}"; show-text "${description}"'';
in
{
  custom.programs.mpv = {
    # auto apply anime shaders for anime videos
    profiles.anime = {
      profile-desc = "Anime";
      # only activate within anime directory
      profile-cond = "path:find('Anime/')";

      # https://kokomins.wordpress.com/2019/10/14/mpv-config-guide/#advanced-video-scaling-config
      # deband-iterations = 2; # Range 1-16. Higher = better quality but more GPU usage. >5 is redundant.
      # deband-threshold = 35; # Range 0-4096. Deband strength.
      # deband-range = 20; # Range 1-64. Range of deband. Too high may destroy details.
      # deband-grain = 5; # Range 0-4096. Inject grain to cover up bad banding, higher value needed for poor sources.

      # set shader defaults
      glsl-shaders = shaderList anime4k_shaders;

      dscale = "mitchell";
      cscale = "spline64"; # or ewa_lanczossoft
    };
    bindings = {
      # clear all shaders
      "CTRL+0" = ''no-osd change-list glsl-shaders clr ""; show-text "Shaders cleared"'';
    }
    // listToAttrs (
      imap
        (i: v: {
          name = "CTRL+${toString i}";
          value = v;
        })
        [
          # Anime4K shaders
          (createShaderKeybind anime4k_shaders "Anime4K: Mode A (HQ)")
          # NVScaler shaders
          (createShaderKeybind [ "NVScaler" ] "NVScaler x2")
          # AMD FSR shaders
          (createShaderKeybind [ "FSR" ] "AMD FidelityFX Super Resolution")
          # AMD Contrast Adaptive Sharpening
          (createShaderKeybind [ "CAS-scaled" ] "AMD FidelityFX Contrast Adaptive Sharpening")
          # FSRCNNX shaders
          (createShaderKeybind [ "FSRCNNX_x2_16-0-4-1" ] "FSRCNNX High")
          (createShaderKeybind [ "FSRCNNX_x2_8-0-4-1" ] "FSRCNNX")
          # NNEDI3 shaders
          (createShaderKeybind [ "nnedi3-nns256-win8x6.hook" ] "NNEDI3")
        ]
    );
  };
}
