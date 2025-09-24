{ config, lib, ... }:
let
  inherit (lib) concatMapStringsSep literalExpression mkOption;
  inherit (lib.types) attrs listOf str;
in
{
  options.custom = {
    # type referenced from nixpkgs:
    # https://github.com/NixOS/nixpkgs/blob/554be6495561ff07b6c724047bdd7e0716aa7b46/nixos/modules/programs/dconf.nix#L121C9-L134C11
    dconf.settings = mkOption {
      type = attrs;
      default = { };
      description = "An attrset used to generate dconf keyfile.";
      example = literalExpression ''
        with lib.gvariant;
        {
          "com/raggesilver/BlackBox" = {
            scrollback-lines = mkUint32 10000;
            theme-dark = "Tommorow Night";
          };
        }
      '';
    };

    gtk = {
      bookmarks = mkOption {
        type = listOf str;
        default = [ ];
        example = [ "file:///home/jane/Documents" ];
        description = "File browser bookmarks.";
      };
    };
  };

  config = {
    hj.files = {
      ".config/gtk-3.0/bookmarks".text = concatMapStringsSep "\n" (
        b: "file://${b}"
      ) config.custom.gtk.bookmarks;
    };

    programs.dconf = {
      enable = true;

      # custom option, the default nesting is horrendous
      profiles.user.databases = [
        { settings = config.custom.dconf.settings; }
      ];
    };
  };
}
