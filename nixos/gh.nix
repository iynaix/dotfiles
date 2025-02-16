{
  config,
  lib,
  pkgs,
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

      custom.persist = {
        home.directories = [ ".config/gh" ];
      };
    };
  }

  # setup auth token for gh if sops is enabled
  (lib.mkIf config.custom.sops.enable {
    sops.secrets.github_token.owner = user;

    # wrap gh to set GITHUB_TOKEN
    hm.programs.gh.package = pkgs.symlinkJoin {
      name = "gh";
      paths = [ pkgs.gh ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = # sh
        ''
          wrapProgram $out/bin/gh \
            --run 'export GITHUB_TOKEN=$(cat ${config.sops.secrets.github_token.path})'
        '';
      meta.mainProgram = "gh";
    };
  })
]
