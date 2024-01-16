{
  config,
  lib,
  pkgs,
  user,
  ...
}: {
  # for github auth
  sops.secrets.github_token.owner = user;

  hm = {
    programs.gh = {
      enable = true;
      # https://github.com/nix-community/home-manager/issues/4744#issuecomment-1849590426
      settings = {
        version = 1;
      };
    };

    custom.shell.functions = {
      # provide auth token for gh
      gh = let
        token_path = config.sops.secrets.github_token.path;
        gh = lib.getExe pkgs.gh;
      in {
        bashBody = ''GITHUB_TOKEN="$(cat ${token_path})" ${gh} "$@"'';
        fishBody = ''GITHUB_TOKEN="$(cat ${token_path})" ${gh} $argv'';
      };
    };
  };
}
