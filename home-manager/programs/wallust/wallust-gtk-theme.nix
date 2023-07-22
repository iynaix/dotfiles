{pkgs ? import <nixpkgs> {}}:
pkgs.writeShellApplication {
  name = "wallust-gtk-theme";

  runtimeInputs = with pkgs; [
    python3
    sassc
  ];

  text = ''
    THEME_DIR="$HOME/.themes"
    TEMPLATE_DIR="/tmp/wallust-gtk-theme"
    mkdir -p "$THEME_DIR"

    # overwrite previous copy
    cp -rf ${pkgs.colloid-gtk-theme.src}* "$TEMPLATE_DIR"
    chown -R "$USER" "$TEMPLATE_DIR"
    chmod -R 766 "$TEMPLATE_DIR"

    # generate new color palette
    python3 ${./generate-gtk-theme.py} "$TEMPLATE_DIR/src/sass/_color-palette-default.scss"

    # build theme
    cd "$TEMPLATE_DIR"
    ./install.sh --name wallust --theme default --color dark --size compact --dest "$THEME_DIR"
  '';
}
