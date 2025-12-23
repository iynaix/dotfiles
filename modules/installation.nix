{
  perSystem =
    { pkgs, ... }:
    let
      repo_url = "https://raw.githubusercontent.com/iynaix/dotfiles";
    in
    {
      packages = rec {
        default = install;

        install = pkgs.writeShellApplication {
          name = "iynaixos-install";
          runtimeInputs = [ pkgs.curl ];
          text = /* sh */ "sh <(curl -L ${repo_url}/main/install.sh)";
        };

        recover = pkgs.writeShellApplication {
          name = "iynaixos-recover";
          runtimeInputs = [ pkgs.curl ];
          text = /* sh */ "sh <(curl -L ${repo_url}/main/recover.sh)";
        };
      };
    };
}
