{
  pkgs,
  host,
  user,
  config,
  ...
}: {
  imports = [./am5.nix ./audio.nix ./backlight.nix ./hdds.nix];
}
