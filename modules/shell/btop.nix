{
  inputs,
  lib,
  self,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    isBool
    isString
    mkDefault
    mkEnableOption
    mkOption
    ;
  btopOptions = {
    cudaSupport = mkEnableOption {
      description = "Enable nvidia support for btop";
    };

    rocmSupport = mkEnableOption {
      description = "Enable radeon support for btop";
    };

    extraSettings = mkOption {
      type =
        with lib.types;
        attrsOf (oneOf [
          bool
          float
          int
          str
        ]);
      default = { };
      example = {
        color_theme = "Default";
        theme_background = false;
      };
      description = ''
        Options to add to {file}`btop.conf` file.
        See <https://github.com/aristocratos/btop#configurability>
        for options.
      '';
    };
  };
in
{
  flake.wrapperModules.btop = inputs.wrappers.lib.wrapModule (
    { config, wlib, ... }:
    let
      toBtopConf = lib.generators.toKeyValue {
        mkKeyValue = lib.generators.mkKeyValueDefault {
          mkValueString =
            v:
            if isBool v then
              (if v then "True" else "False")
            else if isString v then
              ''"${v}"''
            else
              toString v;
        } " = ";
      };
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
      options = btopOptions // {
        "btop.conf" = lib.mkOption {
          type = wlib.types.file config.pkgs;
          default.content = toBtopConf (baseBtopConf // config.extraSettings);
          visible = false;
        };
      };

      config.package = mkDefault (
        config.pkgs.btop.override {
          inherit (config) cudaSupport;
          inherit (config) rocmSupport;
        }
      );
      config.flags = {
        "--config" = toString config."btop.conf".path;
      };
    }
  );

  # expose generic btop package without disks set
  perSystem =
    { pkgs, ... }:
    {
      packages.btop' = (self.wrapperModules.btop.apply { inherit pkgs; }).wrapper;
    };

  flake.nixosModules.core =
    {
      config,
      host,
      pkgs,
      ...
    }:
    {
      options.custom = {
        programs.btop = btopOptions // {
          # convenience option to add disks to btop
          disks = mkOption {
            type = with lib.types; listOf str;
            default = [ ];
            description = "List of disks to monitor in btop";
          };
        };
      };

      config = {
        nixpkgs.overlays = [
          (_: prev: {
            # overlay so that security wrappers for xps can pick it up
            btop =
              (self.wrapperModules.btop.apply {
                pkgs = prev;
                rocmSupport = host == "desktop" || host == "framework";
                extraSettings = {
                  disks_filter = concatStringsSep " " (
                    [
                      "/"
                      "/boot"
                      "/persist"
                    ]
                    ++ config.custom.programs.btop.disks
                  );
                }
                // config.custom.programs.btop.extraSettings;
              }).wrapper;
          })
        ];

        environment.systemPackages = [
          pkgs.btop # overlay-ed above
        ];

        custom.programs.print-config = {
          btop = /* sh */ ''cat "${pkgs.btop.flags."--config"}"'';
        };
      };
    };
}
