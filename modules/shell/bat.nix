{ pkgs, ... }:
{
  custom.wrappers = [
    (
      { pkgs, ... }:
      {
        wrappers.bat = {
          basePackage = pkgs.bat;
          prependFlags = [
            "--theme"
            "base16"
            "--style"
            "grid"
          ];
        };
        # batman with completions
        wrappers.batman = {
          basePackage = pkgs.bat-extras.batman;
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
        };
      }
    )
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
