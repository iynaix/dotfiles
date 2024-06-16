{
  git,
  nh,
  lib,
  writeShellApplication,
  # variables
  dots ? "$HOME/projects/dotfiles",
  name ? "hsw",
  host ? "desktop",
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
        "@@dots@@"
        "@@host@@"
      ]
      [
        # not using toString trips up nix flake check
        (toString dots)
        (toString host)
      ]
      (lib.readFile ./hsw.sh);

  meta = {
    description = "Switch to a different home-manager configuration";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ iynaix ];
    platforms = lib.platforms.linux;
  };
}
