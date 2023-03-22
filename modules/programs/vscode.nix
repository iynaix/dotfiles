{
  pkgs,
  user,
  ...
}: {
  config = {
    home-manager.users.${user} = {
      # fix for error fail to delete using trash
      # https://github.com/microsoft/vscode/issues/101920#issuecomment-710660241
      home.sessionVariables = {
        ELECTRON_TRASH = "gio";
      };

      home.packages = [pkgs.vscode];
    };

    iynaix.persist.home.directories = [
      ".config/Code"
      ".vscode"
    ];
  };
}
