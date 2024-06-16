{
  git,
  lib,
  nh,
  writeShellApplication,
  # variables
  dots ? "$HOME/projects/dotfiles",
  host ? "desktop",
  name ? "nsw",
  nhCommand ? "switch",
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
        "@@nhCommand@@"
      ]
      [
        # not using toString trips up nix flake check
        (toString dots)
        (toString host)
        (toString nhCommand)
      ]
      (lib.readFile ./nsw.sh);

  meta = {
    description = "Switch to a different nixos configuration";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ iynaix ];
    platforms = lib.platforms.linux;
  };
}
