{ inputs, pkgs, ... }:
let
  bat-wrapped = inputs.wrapper-manager.lib.wrapWith pkgs {
    basePackage = pkgs.bat;
    prependFlags = [
      "--theme"
      "base16"
      "--style"
      "grid"
    ];
  };
  # batman with completions
  batman-wrapped = inputs.wrapper-manager.lib.wrapWith pkgs {
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
in
{
  environment.systemPackages = [
    bat-wrapped
    batman-wrapped
  ];

  programs = {
    # use bat for colored help
    fish.shellAbbrs = {
      "--help" = {
        position = "anywhere";
        expansion = "--help | bat --plain --language=help";
      };
    };
  };
}
