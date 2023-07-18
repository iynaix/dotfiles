{
  pkgs,
  config,
  user,
  ...
}: {
  config = {
    environment.systemPackages = [config.iynaix.terminal.fakeGnomeTerminal];

    # set as default shell for user
    environment = {
      shells = [pkgs.zsh];
      homeBinInPath = true;
    };

    programs.zsh = let
      zdotdir = "/home/${user}/.config/zsh";
      histFile = "${zdotdir}/.zsh_history";
    in {
      enable = true;
      # use home-manager config
      shellInit = "source ${zdotdir}/.zshenv";
      interactiveShellInit = "source ${zdotdir}/.zshrc";
      histFile = histFile;
    };
  };
}
