{pkgs, ...}: {
  home.packages = with pkgs; [
    vscode
  ];

  iynaix.persist.home.directories = [
    ".config/Code"
    ".vscode"
  ];
}
