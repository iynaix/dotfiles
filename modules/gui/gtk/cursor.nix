{ lib, ... }:
{
  flake.modules.nixos.core =
    { pkgs, ... }:
    {
      options.custom = {
        gtk = {
          cursor = {
            package = lib.mkOption {
              type = lib.types.package;
              default = pkgs.simp1e-cursors;
              description = "Package providing the cursor theme.";
            };

            name = lib.mkOption {
              type = lib.types.str;
              default = "Simp1e-Tokyo-Night";
              description = "The cursor name within the package.";
            };

            size = lib.mkOption {
              type = lib.types.int;
              default = 28;
              description = "The cursor size.";
            };
          };
        };
      };
    };

  flake.modules.nixos.gui =
    { config, ... }:
    let
      gtkCursor = config.custom.gtk.cursor;
    in
    {
      environment = {
        sessionVariables = {
          XCURSOR_SIZE = gtkCursor.size;
          XCURSOR_THEME = gtkCursor.name;
        };

        systemPackages = [
          gtkCursor.package
        ];
      };

      # Add cursor icon link to $XDG_DATA_HOME/icons as well for redundancy.
      hj.xdg.data.files = {
        "icons/${gtkCursor.name}".source = "${gtkCursor.package}/share/icons/${gtkCursor.name}";
      };
    };
}
