{
  pkgs,
  lib,
  isNixOS,
  ...
}: {
  home.packages = lib.mkIf isNixOS (with pkgs; [
    vscode
  ]);

  iynaix.persist.home.directories = [
    ".config/Code"
    ".vscode"
  ];
}
