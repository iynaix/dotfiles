{ inputs, lib, ... }:
{
  flake.nixosModules.core =
    { config, pkgs, ... }:
    {
      options.custom = {
        symlinks = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = "Symlinks to create in the format { dest = src;}";
        };
      };

      config = {
        # automount disks
        programs.dconf.enable = true;
        services.gvfs.enable = true;

        hjem = {
          # thanks for not fucking wasting my time
          clobberByDefault = true;
          linker = inputs.hjem.packages.${pkgs.stdenv.hostPlatform.system}.smfh;
        };

        # create symlink to dotfiles from /etc/nixos
        custom.symlinks = {
          "/etc/nixos" = "/persist${config.hj.directory}/projects/dotfiles";
        };

        # create symlinks
        systemd.tmpfiles.rules = [
          # cleanup systemd coredumps once a week
          "D! /var/lib/systemd/coredump root root 7d"
        ]
        ++ (lib.mapAttrsToList (dest: src: "L+ ${dest} - - - - ${src}") config.custom.symlinks);
      };
    };
}
