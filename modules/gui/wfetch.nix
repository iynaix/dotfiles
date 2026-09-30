{
  tags = [ "gui" ];

  config =
    { pkgs, user, ... }:
    {
      environment.systemPackages = [
        pkgs.imagemagick
      ];

      custom.programs = {
        noctalia.user-templates = {
          wfetch = {
            # dummy values so noctalia doesn't complain
            input_path = "/home/${user}/.config/user-dirs.conf";
            output_path = "/dev/null";
            post_hook = "bash -c 'pgrep -f .wfetch-wrapped >/dev/null && pkill -SIGUSR2 .wfetch-wrapped || true'";
          };
        };
      };
    };
}
