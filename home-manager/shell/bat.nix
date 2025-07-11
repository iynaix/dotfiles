{ pkgs, ... }:
{

  programs = {
    bat = {
      enable = true;
      config = {
        style = "grid";
      };
      extraPackages = [
        (pkgs.symlinkJoin {
          name = "batman";
          paths = [ pkgs.bat-extras.batman ];
          postBuild = # sh
            ''
              mkdir -p $out/share/bash-completion/completions
              echo 'complete -F _comp_cmd_man batman' > $out/share/bash-completion/completions/batman

              mkdir -p $out/share/fish/vendor_completions.d
              echo 'complete batman --wraps man' > $out/share/fish/vendor_completions.d/batman.fish

              mkdir -p $out/share/zsh/site-functions
              cat << EOF > $out/share/zsh/site-functions/_batman
              #compdef batman
              _man "$@"
              EOF
            '';
          meta.mainProgram = "batman";
        })
      ];
    };

    # use bat for colored help
    fish.shellAbbrs = {
      "--help" = {
        position = "anywhere";
        expansion = "--help | bat --plain --language=help";
      };
    };
  };
}
