{
  config,
  lib,
  pkgs,
  user,
  ...
}: let
  cfg = config.home-manager.users.${user}.iynaix.shell;
  isZsh = cfg.package == pkgs.zsh;
in {
  environment.shells = lib.mkIf isZsh [pkgs.zsh];

  # default to zsh for all users
  users.defaultUserShell = lib.mkIf isZsh pkgs.zsh;

  # setup zsh and bash system wide
  programs = {
    zsh.enable = true;

    bash.interactiveShellInit = cfg.initExtra;
    zsh.interactiveShellInit = cfg.initExtra;

    bash.loginShellInit = cfg.profileExtra;
    zsh.loginShellInit = cfg.profileExtra;
  };
}
