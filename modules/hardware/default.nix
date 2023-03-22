{
  pkgs,
  host,
  user,
  config,
  ...
}: {
  imports = [./audio.nix ./backlight.nix];
}
