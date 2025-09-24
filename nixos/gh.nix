{
  config,
  lib,
  pkgs,
  user,
  ...
}:
let
  inherit (lib) getExe nameValuePair listToAttrs;
  ghConf = pkgs.writeText "config.yml" (lib.strings.toJSON { version = 1; });
  ghHosts = pkgs.writeText "hosts.yml" (
    lib.strings.toJSON {
      github.com = {
        git_protocol = "ssh";
        users.iynaix = { };
        user = "iynaix";
      };
    }
  );
  ghDir = pkgs.runCommand "gh" { } ''
    mkdir -p $out
    cp ${ghConf} $out/config.yml
    cp ${ghHosts} $out/hosts.yml
  '';
in
{
  # setup auth token for gh
  sops.secrets.github_token.owner = user;

  # wrap gh to set GITHUB_TOKEN
  # custom.wrappers = [
  #   (
  #     { pkgs, ... }:
  #     {
  #       wrappers.gh = {
  #         basePackage = pkgs.gh;
  #         env.GH_CONFIG_DIR.value = "${ghConf}";
  #         wrapperType = "shell";
  #         wrapFlags = [
  #           "--run"
  #           ''export GITHUB_TOKEN="$(cat ${config.sops.secrets.github_token.path})"''
  #         ];
  #       };
  #     }
  #   )
  # ];

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

  # wait for https://github.com/viperML/wrapper-manager/issues/33 to be fixed
  nixpkgs.overlays = [
    (_: prev: {
      gh = prev.symlinkJoin {
        name = "gh";
        paths = [ prev.gh ];
        buildInputs = [ prev.makeWrapper ];
        postBuild = # sh
          ''
            wrapProgram $out/bin/gh \
              --set-default GH_CONFIG_DIR "${ghDir}" \
              --run 'export GITHUB_TOKEN=$(cat "${config.sops.secrets.github_token.path}")'
          '';
        meta.mainProgram = "gh";
      };
    })

  ];

  environment.systemPackages = [ pkgs.gh ];
}
