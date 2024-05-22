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

      custom.persist = {
        home.directories = [ ".config/gh" ];
      };
    };
  }

  # setup auth token for gh if sops is enabled
  (lib.mkIf config.custom.sops.enable {
    sops.secrets.github_token.owner = user;

    # wrap gh to set GITHUB_TOKEN, an overlay is used so gh can be used within other scripts
    nixpkgs.overlays = [
      (_: prev: {
        gh = prev.symlinkJoin {
          name = "gh";
          paths = [ prev.gh ];
          buildInputs = [ prev.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/gh \
              --run 'export GITHUB_TOKEN=$(cat ${config.sops.secrets.github_token.path})'
          '';
        };
      })
    ];
  })
]
