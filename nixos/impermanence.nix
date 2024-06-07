{
  config,
  lib,
  pkgs,
  user,
  ...
}:
let
  cfg = config.custom.persist;
  hmPersistCfg = config.hm.custom.persist;
in
{
  # clear /tmp on boot, since it's a zfs dataset
  boot.tmp.cleanOnBoot = true;

  # root and home on tmpfs
  # neededForBoot is required, so there won't be permission errors creating directories or symlinks
  # https://github.com/nix-community/impermanence/issues/149#issuecomment-1806604102
  fileSystems."/" = {
    device = "tmpfs";
    fsType = "tmpfs";
    neededForBoot = true;
    options = [
      "defaults"
      "size=1G"
      "mode=755"
    ];
  };

  # shut sudo up
  security.sudo.extraConfig = "Defaults lecture=never";

  custom.shell.packages = {
    # show all files stored on tmpfs, useful for finding files to persist
    show-tmpfs = {
      runtimeInputs = [ pkgs.fd ];
      text =
        let
          wallustExcludes = lib.pipe config.hm.custom.wallust.templates [
            lib.attrValues
            (map (a: a.target))
            (lib.filter (t: !(lib.hasInfix "wallust" t)))
            (map (t: ''--exclude "${t}" \''))
            lib.concatLines
          ];
        in
        ''
          sudo fd --one-file-system --base-directory / --type f --hidden --list-details \
            --exclude "/etc/{ssh,machine-id,passwd,shadow}" \
            ${wallustExcludes} \
            --exclude "*.timer" \
            --exclude "/var/lib/NetworkManager" \
            --exclude "/home/iynaix/.cache/{bat,fontconfig,nvidia,nvim/catppuccin,pre-commit,swww,wallust}"
        '';
    };
  };

  # setup persistence
  environment.persistence = {
    "/persist" = {
      hideMounts = true;
      files = [ "/etc/machine-id" ] ++ cfg.root.files;
      directories = [
        "/var/log" # systemd journal is stored in /var/log/journal
      ] ++ cfg.root.directories;

      users.${user} = {
        files = cfg.home.files ++ hmPersistCfg.home.files;
        directories = [
          "projects"
          ".cache/dconf"
          ".config/dconf"
        ] ++ cfg.home.directories ++ hmPersistCfg.home.directories;
      };
    };

    "/persist/cache" = {
      hideMounts = true;
      directories = cfg.root.cache;

      users.${user} = {
        directories = hmPersistCfg.home.cache;
      };
    };
  };
}
