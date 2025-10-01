{ pkgs, ... }:
{
  custom.wrappers = [
    (_: prev: {
      bat = {
        flags = {
          "--theme" = "base16";
          "--style" = "grid";
        };
      };
      # batman with completions
      batman = {
        package = prev.bat-extras.batman.overrideAttrs (o: {
          postInstall =
            (o.postInstall or "")
            # sh
            + ''
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
        });
      };
    })
  ];

  environment.systemPackages = with pkgs; [
    bat
    batman
  ];

  programs = {
    # use bat for colored help
    fish.shellAbbrs = {
      "--position anywhere -- --help" = "--help | bat --plain --language=help";
    };
  };
}
