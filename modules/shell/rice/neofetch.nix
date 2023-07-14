{
  pkgs,
  user,
  ...
}: let
  waifufetch = pkgs.writeShellScriptBin "waifufetch" ''
    source $HOME/.cache/wallust/colors.sh

    img_out=/tmp/neofetch-"$color4"-"$color6".png

    ${pkgs.imagemagick}/bin/magick ${./nixos.png} -fuzz 10% -fill "$color4" -opaque "#5278c3" -fuzz 10% -fill "$color6" -opaque "#7fbae4" "$img_out"

    if [ $TERM = "xterm-kitty" ]; then
      neofetch --kitty "$img_out" --config ${./neofetch.conf}
    else
      neofetch --sixel "$img_out" --config ${./neofetch.conf}
    fi
  '';
in {
  imports = [./cava.nix];

  config = {
    home-manager.users.${user} = {
      home.packages = with pkgs; [
        neofetch
        waifufetch
      ];

      programs.zsh.shellAliases = {
        neofetch = "neofetch --config ${./neofetch.conf}";
      };
    };
  };
}
