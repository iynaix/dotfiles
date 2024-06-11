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
        dots
        host
      ]
      (builtins.readFile ./nsw.sh);
}
