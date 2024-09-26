{
  config,
  lib,
  user,
  ...
}:

lib.mkMerge [
  (lib.mkIf config.custom.sops.enable {
    sops.secrets.anilist_token.owner = user;
    hm = {
      home.file = {
        ".local/share/jerry/anilist_token.txt" = {
          force = true;
          source = config.sops.secrets.anilist_token.path;
        };
      };
    };
  })
]
