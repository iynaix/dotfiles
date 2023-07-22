{pkgs, ...}: {
  home.packages = [pkgs.vscode];

  iynaix.persist.home.directories = [
    ".config/Code"
    ".vscode"
  ];
}
