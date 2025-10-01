{
  config,
  lib,
  pkgs,
  user,
  ...
}:
let
  inherit (lib) getExe nameValuePair listToAttrs;
  ghDir = pkgs.writeTextDir "/config.yml" (lib.strings.toJSON { version = 1; });
in
{
  # setup auth token for gh
  sops.secrets.github_token.owner = user;

  # wrap gh to set GITHUB_TOKEN
  custom.wrappers = [
    (_: _prev: {
      gh = {
        env.GH_CONFIG_DIR = ghDir;
        preHook = ''
          GITHUB_TOKEN=$(cat "${config.sops.secrets.github_token.path}")
          export GITHUB_TOKEN
        '';
      };
    })
  ];

  # needed for github authentication for private repos
  # adapted from home-manager:
  # https://github.com/nix-community/home-manager/blob/142acd7a7d9eb7f0bb647f053b4ddfd01fdfbf1d/modules/programs/gh.nix#L191
  programs.git.config = {
    credential =
      [
        "https://github.com"
        "https://gist.github.com"
      ]
      |> map (
        host:
        nameValuePair host {
          helper = [
            ""
            "${getExe pkgs.gh} auth git-credential"
          ];
        }
      )
      |> listToAttrs;
  };

  environment.systemPackages = [ pkgs.gh ];
}
