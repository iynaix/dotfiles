{
  config,
  lib,
  user,
  ...
}:

(lib.mkIf config.custom.sops.enable {
  sops.secrets.anilist_token.owner = user;
  custom.symlinks = {
    "/home/${user}/.local/share/jerry/anilist_token.txt" = "${config.sops.secrets.anilist_token.path}";
  };
  # The following does the same thing:
  # systemd.tmpfiles.rules = [
  #   "L+ /home/${user}/.local/share/jerry/anilist_token.txt - - - - ${config.sops.secrets.anilist_token.path}"
  # ];
})
