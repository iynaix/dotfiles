{ inputs, lib, ... }:
let
  inherit (lib) getExe nameValuePair listToAttrs;
in
{
  flake.nixosModules.core =
    {
      config,
      pkgs,
      user,
      ...
    }:
    {
      # setup auth token for gh
      sops.secrets.github_token.owner = user;

      nixpkgs.overlays = [
        (_: prev: {
          # wrap gh to set GITHUB_TOKEN
          gh = inputs.wrappers.lib.wrapPackage {
            pkgs = prev;
            package = prev.gh;
            env.GH_CONFIG_DIR = pkgs.writeTextDir "/config.yml" (lib.strings.toJSON { version = 1; });
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

      environment.systemPackages = [ pkgs.gh ]; # overlay-ed above
    };
}
