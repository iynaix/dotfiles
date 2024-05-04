{
  config,
  lib,
  user,
  ...
}:
lib.mkMerge [
  {
    hm = {
      programs.gh = {
        enable = true;
        # https://github.com/nix-community/home-manager/issues/4744#issuecomment-1849590426
        settings = {
          version = 1;
        };
      };
    };
  }

  # setup auth token for gh if sops is enabled
  (lib.mkIf config.custom.sops.enable {
    sops.secrets.github_token.owner = user;

    hm.home.sessionVariables = {
      GITHUB_TOKEN = "$(cat ${config.sops.secrets.github_token.path})";
    };
  })
]
