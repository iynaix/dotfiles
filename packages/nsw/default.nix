{
  git,
  lib,
  nh,
  writeShellApplication,
  # variables
  dots ? "$HOME/projects/dotfiles",
  host ? "desktop",
  name ? "nsw",
}:
writeShellApplication {
  inherit name;
  runtimeInputs = [
    git
    nh
  ];
  text =
    lib.replaceStrings
      [
        "@dots@"
        "@host@"
      ]
      [
        # not using toString trips up nix flake check
        (toString dots)
        (toString host)
      ]
      (lib.readFile ./nsw.sh);

  meta = {
    description = "nh wrapper";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ iynaix ];
    platforms = lib.platforms.linux;
  };
}
