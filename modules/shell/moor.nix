{ inputs, lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.moor = inputs.wrappers.lib.wrapPackage {
        inherit pkgs;
        package = pkgs.moor;
        flags = {
          "--quit-if-one-screen" = true;
          "--no-linenumbers" = true;
          "--statusbar" = "bold";
          "-terminal-fg" = true;
        };
        passthru.shellAliases = {
          less = "moor";
        };
      };
    };

  flake.modules.nixos.core =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [
        (_: _prev: {
          moor = pkgs.custom.moor;
        })
      ];

      environment = {
        variables = {
          PAGER = "moor";
          SYSTEMD_PAGER = "moor";
          SYSTEMD_PAGERSECURE = "1";
        };
      };

      custom.programs.print-config = {
        moor = /* sh */ ''moor --lang sh "${lib.getExe pkgs.moor}"'';
      };
    };
}
