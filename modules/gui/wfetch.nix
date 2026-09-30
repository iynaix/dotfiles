{
  tags = [ "gui" ];

  config =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.imagemagick
      ];

      custom.programs = {
        noctalia.user-templates = {
          wfetch = {
            output_path = "/dev/null";
            post_hook = "bash -c 'pgrep -f .wfetch-wrapped >/dev/null && pkill -SIGUSR2 .wfetch-wrapped || true'";
          };
        };
      };
    };
}
