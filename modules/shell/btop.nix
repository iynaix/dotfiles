{
  inputs,
  lib,
  ...
}:
let
  baseBtopConf = {
    color_theme = "TTY";
    theme_background = false;
    cpu_single_graph = true;
    # base_10_sizes = true;
    show_gpu_info = "Off"; # don't show gpu info in cpu box
    show_disks = true;
    show_swap = true;
    swap_disk = false;
    use_fstab = false;
    only_physical = false;
    zfs_arc_cached = true;
    shown_boxes = "cpu mem net proc gpu0";
    gpu_mirror_graph = false;
  };
in
{
  # expose generic btop package without disks set
  perSystem =
    { pkgs, ... }:
    {
      packages.btop = inputs.wrappers.wrappers.btop.wrap {
        inherit pkgs;
        settings = baseBtopConf;
      };
    };

  flake.modules.nixos.core =
    { config, pkgs, ... }:
    let
      inherit (config.custom.constants) host;
    in
    {
      options.custom = {
        programs.btop = {
          settings = lib.mkOption {
            type = lib.types.submodule { freeformType = lib.types.attrs; };
            description = "Btop settings, See https://github.com/aristocratos/btop#configurability for available options";
          };

          # convenience option to add disks to btop
          disks = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "List of disks to monitor in btop";
          };
        };
      };

      config = {
        nixpkgs.overlays = [
          (_: prev: {
            # overlay so that security wrappers for xps can pick it up
            btop = inputs.wrappers.wrappers.btop.wrap {
              pkgs = prev;
              package = prev.btop.override {
                rocmSupport = host == "desktop" || host == "framework";
              };
              settings = baseBtopConf // {
                color_theme = "noctalia";
                disks_filter = lib.concatStringsSep " " (
                  [
                    "/"
                    "/boot"
                    "/persist"
                  ]
                  ++ config.custom.programs.btop.disks
                );
              };
            };
          })
        ];

        environment.systemPackages = [
          pkgs.btop # overlay-ed above
        ];

        custom.programs.print-config = {
          btop = /* sh */ ''moor --lang ini "${pkgs.btop.configuration.flags."--config".data}"'';
        };
      };
    };
}
