{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) concatStringsSep mkOption;
  inherit (lib.types) listOf str;
in
{
  options.custom = {
    btop = {
      disks = mkOption {
        type = listOf str;
        default = [ ];
        description = "List of disks to monitor in btop";
      };
    };
  };

  config = {
    programs.btop = {
      enable = true;
      package = pkgs.btop.override {
        cudaSupport = config.custom.nvidia.enable;
        rocmSupport = config.custom.radeon.enable;
      };
      settings = {
        color_theme = "TTY";
        theme_background = false;
        cpu_single_graph = true;
        # base_10_sizes = true;
        show_disks = true;
        show_swap = true;
        swap_disk = false;
        use_fstab = false;
        only_physical = false;
        disks_filter = concatStringsSep " " (
          [
            "/"
            "/boot"
            "/persist"
          ]
          ++ config.custom.btop.disks
        );
        shown_boxes = "cpu mem net proc gpu0";
        gpu_mirror_graph = false;
      };
    };
  };
}
