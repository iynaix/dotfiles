# create a cross shell config
{
  config,
  lib,
  pkgs,
  ...
}:
let
  proj_dir = "/persist${config.home.homeDirectory}/projects";
in
{
  home = {
    shellAliases =
      {
        ":e" = "nvim";
        ":q" = "exit";
        c = "clear";
        cat = "bat";
        ccat = "command cat";
        crate = "cargo";
        isodate = ''date - u + "%Y-%m-%dT%H:%M:%SZ"'';
        man = lib.getExe' pkgs.bat-extras.batman "batman";
        mime = "xdg-mime query filetype";
        mkdir = "mkdir -p";
        mount = "mount --mkdir";
        open = "xdg-open";
        py = "python";
        coinfc = "pj coinfc";

        # cd aliases
        ".." = "cd ..";
        "..." = "cd ../..";
      }
      //
      # add shortcuts for quick cd in shell
      lib.mapAttrs (_: value: "cd ${value}") config.custom.shortcuts;
  };

  custom.shell.packages = {
    fdnix = {
      runtimeInputs = [ pkgs.fd ];
      text = ''fd "$@" /nix/store'';
    };
    md = ''[[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1"'';
    # improved which for nix
    where = ''readlink -f "$(which "$1")"'';
    cwhere = ''cat "$(where "$1")"'';
    ywhere = {
      runtimeInputs = with pkgs; [
        yazi
        custom.shell.where
      ];
      text = ''yazi "$(dirname "$(dirname "$(where "$1")")")"'';
    };
  };

  # pj cannot be implemented as script as it needs to change the directory of the shell
  # bash function and completion for pj
  programs.bash.initExtra = ''
    function pj() {
        cd ${proj_dir}
        if [[ $# -eq 1 ]]; then
          cd "$1";
        fi
    }
    _pj() {
        ( cd ${proj_dir}; printf "%s\n" "$2"* )
    }
    complete -o nospace -C _pj pj
  '';

  programs.fish.functions.pj = ''
    cd ${proj_dir}
    if test (count $argv) -eq 1
      cd $argv[1]
    end
  '';

  # fish completion
  xdg.configFile."fish/completions/pj.fish".text = ''
    function _pj
        find ${proj_dir} -maxdepth 1 -type d -exec basename {} \;
    end
    complete --no-files --command pj --arguments "(_pj)"
  '';
}
