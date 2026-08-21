{
  tags = [ "gui" ];

  config =
    { config, pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.imagemagick
      ];

      custom.programs = {
        noctalia.colors = {
          wfetch = {
            # dummy values so noctalia doesn't complain
            input_path = "${config.hj.xdg.config.directory}/user-dirs.conf";
            output_path = "/dev/null";
            post_hook = "bash -c 'pgrep -f .wfetch-wrapped >/dev/null && pkill -SIGUSR2 .wfetch-wrapped || true'";
          };
        };
      };
    };
}
