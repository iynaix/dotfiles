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
        dots
        host
        nhCommand
      ]
      (builtins.readFile ./nsw.sh);
}
