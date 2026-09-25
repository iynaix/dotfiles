{
  packages =
    { pkgs, ... }:
    {
      simp1e-dynamic-cursor-theme = pkgs.writeShellApplication {
        name = "simp1e-dynamic-cursor-theme";
        runtimeInputs = with pkgs; [
          (python3.withPackages (ps: [ ps.pillow ]))
          librsvg.out # otherwise it uses .dev
          xcursorgen
          dconf
        ];

        text = /* sh */ ''
          # $1 is the accent color, $2 is a comma separated list of sizes to generate
          out="/tmp/simp1e-cursors"

          if [ ! -d "$out" ]; then
            cp -r --no-preserve=mode ${pkgs.simp1e-cursors.src} $out
            chmod -R u+w $out
          fi

          rm $out/src/color_schemes/*.txt
          cp "/tmp/Simp1e-Noctalia.txt" "$out/src/color_schemes/Simp1e-Noctalia.txt"

          HOME=/tmp sh $out/build.sh --sizes="$2"

          THEME_NAME="Simp1e-Noctalia-$1"
          ln -s "$out/built_themes/$THEME_NAME" "$HOME/.local/share/icons/$THEME_NAME"

          # update gtk with cursor
          dconf write "/org/gnome/desktop/interface/cursor-theme" "'$THEME_NAME'"

          # update umbriel with cursor
          cat << EOF > "$XDG_CONFIG_HOME/umbriel/cursor.toml"
          [input.cursor]
          theme = "$THEME_NAME"
          EOF
        '';
      };
    };

  tags = [ "gui" ];

  config =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      config = {
        # set dynamic icon theme with noctalia
        custom.programs.noctalia.user-templates = {
          "cursor-theme" = {
            input_path = ./Simp1e-Noctalia.txt;
            output_path = "/tmp/Simp1e-Noctalia.txt";
            post_hook =
              let
                # calculate all possible cursors sizes based on monitor scales
                sizes =
                  config.custom.hardware.monitors
                  |> lib.map (m: lib.ceil (config.custom.gtk.cursor.size * m.scale))
                  |> lib.sort (p: q: p < q)
                  |> lib.unique
                  |> lib.concatMapStringsSep "," toString;
              in
              ''${lib.getExe pkgs.custom.simp1e-dynamic-cursor-theme} "{{ colors.primary.default.hex_stripped }}" "${sizes}"'';
          };
        };
      };
    };
}
