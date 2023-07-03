{
  pkgs,
  user,
  ...
}: {
  config = {
    home-manager.users.${user} = {
      home.packages = with pkgs; [vscode];
    };

    iynaix.persist.home.directories = [
      ".config/Code"
      ".vscode"
    ];
  };
}
