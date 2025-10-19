{ inputs, lib, ... }:
{
  flake.nixosModules.core =
    {
      config,
      host,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        concatStringsSep
        isBool
        isString
        mkOption
        ;
      # btop options and settings config from:
      # https://github.com/nix-community/home-manager/blob/master/modules/programs/btop.nix
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
    in
    {
      options.custom = {
        programs.btop = {
          disks = mkOption {
            type = with lib.types; listOf str;
            default = [ ];
            description = "List of disks to monitor in btop";
          };

          settings = mkOption {
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
      };

      config =
        let
          cfg = config.custom.programs.btop;
          btopConf = pkgs.writeText "btop.conf" (toBtopConf cfg.settings);
          btop' = inputs.wrappers.lib.wrapPackage {
            inherit pkgs;
            package = pkgs.btop.override {
              cudaSupport = host == "desktop";
              rocmSupport = host == "laptop";
            };
            flags = {
              "--config" = btopConf;
            };
          };
        in
        {
          custom = {
            programs.btop.settings = {
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
                ++ cfg.disks
              );
              shown_boxes = "cpu mem net proc gpu0";
              gpu_mirror_graph = false;
            };
          };

          environment.systemPackages = [ btop' ];
        };
    };
}
