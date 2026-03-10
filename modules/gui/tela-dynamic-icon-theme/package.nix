{ lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        tela-dynamic-icon-theme =
          let
            # copy the generated theme directly
            tela-template = pkgs.runCommand "tela-template" { } ''
              # copy the nix icon
              mkdir -p $out/scalable/mimetypes/
              cp ${./nix.svg} $out/scalable/mimetypes/text-x-nix.svg

              # copy everything that is not "@2x", can be generated later
              src="${pkgs.tela-icon-theme}/share/icons/Tela-blue-dark/"
              find "$src" -maxdepth 1 -mindepth 1 ! -name '*@2x' -print0 | xargs -0 -I{} cp -rL {} "$out/"

              # generate a list of all the files that need to be replaced
              ${lib.getExe pkgs.ripgrep} -l "#5677fc" $out | sed "s|$out/||" > $out/replacements.txt
            '';
          in
          # just replace all instances of tela blue
          pkgs.writeShellApplication {
            name = "tela-dynamic-icon-theme";
            runtimeInputs = [
              pkgs.dconf
            ];
            text = ''
              if [[ -z "''${1:-}" ]]; then
                  echo "ERROR: No hex color provided."
                  exit 1
              fi

              THEME_DIR="/tmp/Tela-$1"

              if [[ ! -d "$THEME_DIR" ]]; then
                cp -r ${tela-template} "$THEME_DIR"
                chmod -R +w "$THEME_DIR"

                # replace only for the files in replacements.txt
                xargs -d '\n' -a "$THEME_DIR/replacements.txt" -I {} sed -i "s/#5677fc/$1/g" "$THEME_DIR/{}"

                for dir in 16 22 24 32 scalable;
                  do ln -sr "$THEME_DIR/$dir" "$THEME_DIR/$dir@2x";
                done
              fi

              ln -sfn "$THEME_DIR" "$HOME/.local/share/icons/$1"
              dconf write "/org/gnome/desktop/interface/icon-theme" "'$1'"
            '';
          };
      };
    };

  flake.modules.nixos.gui =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        # associate nix files with nix icon
        (pkgs.writeTextFile {
          name = "nix-mimetype";
          destination = "/share/mime/packages/nix.xml";
          text = ''
            <?xml version="1.0" encoding="UTF-8"?>
            <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
                <mime-type type="text/x-nix">
                    <glob pattern="*.nix"/>
                    <icon name="text-x-nix"/>
                </mime-type>
            </mime-info>
          '';
        })
      ];
    };
}
