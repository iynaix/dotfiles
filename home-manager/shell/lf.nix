{
  pkgs,
  lib,
  config,
  ...
}: let
  mkLfCommands = lib.mapAttrs (name: value: ''
    ''${{
      ${value}
    }}
  '');
  # use kitty to preview images, adapted from:
  # https://github.com/gokcehan/lf/wiki/Previews#with-kitty-and-pistol
  lf-kitty-previewer = pkgs.writeShellApplication {
    name = "lf-kitty-previewer";
    runtimeInputs = with pkgs; [file pistol kitty];
    text = ''
      file=$1
      w=$2
      h=$3
      x=$4
      y=$5

      if [[ "$( file -Lb --mime-type "$file")" =~ ^image ]]; then
          kitten icat --transfer-mode file --stdin no --place "''${w}x''${h}@''${x}x''${y}" "$file" < /dev/null > /dev/tty
          exit 1
      fi

      pistol "$file"
    '';
  };
  lf-kitty-cleaner = pkgs.writeShellApplication {
    name = "lf-kitty-cleaner";
    runtimeInputs = [pkgs.kitty];
    text = "kitten icat --clear --silent --transfer-mode file";
  };
in {
  programs.lf = {
    enable = true;

    settings = {
      preview = true;
      dirfirst = true;
      drawbox = true;
      hidden = true;
      icons = true;
      promptfmt = "\\033[34;1m%d\\033[0m\\033[1m%f\\033[0m";
      ratios = "1:1";
      smartcase = true;
    };

    previewer.source = "${lf-kitty-previewer}/bin/lf-kitty-previewer";

    commands = mkLfCommands {
      open = ''
        case $(file --mime-type "$f" -bL) in
            text/*|application/json) $EDITOR "$f";;
            *) xdg-open "$f" ;;
        esac
      '';
      mkdir = ''
        printf "Directory Name: "
        read ans
        mkdir $ans
      '';
      mkfile = ''
        printf "File Name: "
        read ans
        $EDITOR $ans
      '';
      chmod = ''
        printf "Mode Bits: "
        read ans

        for file in "$fx"
        do
          chmod $ans $file
        done

        lf -remote 'send reload'
      '';
      sudomkfile = ''
        printf "File Name: "
        read ans
        sudo $EDITOR $ans
      '';
      bulkrename = ''
        /bin/sh -c "vimv $(echo -e "$fx" | xargs -i echo "\\'{}\\'" | xargs echo)"
      '';
      setwallpaper = ''%hypr-wallpaper "$f"'';
      fzf_jump = ''
        res="$(find . -maxdepth 3 | fzf --reverse --header='Jump to location')"
        if [ -f "$res" ]; then
          cmd="select"
        elif [ -d "$res" ]; then
          cmd="cd"
        fi
        lf -remote "send $id $cmd \"$res\""
      '';
      unarchive = ''
        case "$f" in
            *.zip) unzip "$f" ;;
            *.tar.gz) tar -xzvf "$f" ;;
            *.tar.bz2) tar -xjvf "$f" ;;
            *.tar) tar -xvf "$f" ;;
            *) echo "Unsupported format" ;;
        esac
      '';
      zip = ''%zip -r "$f" "$f"'';
      tar = ''%tar cvf "$f.tar" "$f"'';
      targz = ''%tar cvzf "$f.tar.gz" "$f"'';
      tarbz2 = ''%tar cjvf "$f.tar.bz2" "$f"'';
    };

    keybindings =
      {
        # Basic Functions
        ee = ''$$EDITOR "$f"'';
        "." = "set hidden!";
        dd = "delete";
        p = "paste";
        x = "cut";
        y = "copy";
        "<enter>" = "open";
        mf = "mkfile";
        mr = "sudomkfile";
        md = "mkdir";
        ch = "chmod";
        w = "setwallpaper";
        r = "rename";
        H = "top";
        L = "bottom";
        R = "reload";
        C = "clear";
        U = "unselect";
        br = "bulkrename";

        # Archive Mappings
        az = "zip";
        at = "tar";
        ag = "targz";
        ab = "targz";
        au = "unarchive";
      }
      # Shortcuts
      // (
        lib.attrsets.mergeAttrsList (lib.mapAttrsToList (name: value: {
            "g${name}" = "cd ${value}";
            "m${name}" = "shell %mv -v ${value}";
            "Y${name}" = "shell %cp -rv ${value}";
          })
          config.iynaix.shortcuts)
      );

    extraConfig = ''
      # Options not exposed by nix
      # set dupfilefmt "%b - copy.%e"
      set incfilter true
      set mouse true
      set cleaner ${lf-kitty-cleaner}/bin/lf-kitty-cleaner
    '';
  };

  # setup icons for lf
  programs.zsh.initExtra = ''
    export LF_ICONS="\
    di=:\
    fi=:\
    ln=:\
    or=:\
    ex=:\
    *.vimrc=:\
    *.viminfo=:\
    *.gitignore=:\
    *.c=:\
    *.cc=:\
    *.clj=:\
    *.coffee=:\
    *.cpp=:\
    *.css=:\
    *.d=:\
    *.dart=:\
    *.erl=:\
    *.exs=:\
    *.fs=:\
    *.go=:\
    *.h=:\
    *.hh=:\
    *.hpp=:\
    *.hs=:\
    *.html=:\
    *.java=:\
    *.jl=:\
    *.js=:\
    *.json=:\
    *.lua=:\
    *.md=:\
    *.php=:\
    *.pl=:\
    *.pro=:\
    *.py=:\
    *.rb=:\
    *.rs=:\
    *.scala=:\
    *.ts=:\
    *.vim=:\
    *.cmd=:\
    *.ps1=:\
    *.sh=:\
    *.bash=:\
    *.zsh=:\
    *.fish=:\
    *.tar=:\
    *.tgz=:\
    *.arc=:\
    *.arj=:\
    *.taz=:\
    *.lha=:\
    *.lz4=:\
    *.lzh=:\
    *.lzma=:\
    *.tlz=:\
    *.txz=:\
    *.tzo=:\
    *.t7z=:\
    *.zip=:\
    *.z=:\
    *.dz=:\
    *.gz=:\
    *.lrz=:\
    *.lz=:\
    *.lzo=:\
    *.xz=:\
    *.zst=:\
    *.tzst=:\
    *.bz2=:\
    *.bz=:\
    *.tbz=:\
    *.tbz2=:\
    *.tz=:\
    *.deb=:\
    *.rpm=:\
    *.jar=:\
    *.war=:\
    *.ear=:\
    *.sar=:\
    *.rar=:\
    *.alz=:\
    *.ace=:\
    *.zoo=:\
    *.cpio=:\
    *.7z=:\
    *.rz=:\
    *.cab=:\
    *.wim=:\
    *.swm=:\
    *.dwm=:\
    *.esd=:\
    *.jpg=:\
    *.jpeg=:\
    *.mjpg=:\
    *.mjpeg=:\
    *.gif=:\
    *.bmp=:\
    *.pbm=:\
    *.pgm=:\
    *.ppm=:\
    *.tga=:\
    *.xbm=:\
    *.xpm=:\
    *.tif=:\
    *.tiff=:\
    *.png=:\
    *.svg=:\
    *.svgz=:\
    *.mng=:\
    *.pcx=:\
    *.mov=:\
    *.mpg=:\
    *.mpeg=:\
    *.m2v=:\
    *.mkv=:\
    *.webm=:\
    *.ogm=:\
    *.mp4=:\
    *.m4v=:\
    *.mp4v=:\
    *.vob=:\
    *.qt=:\
    *.nuv=:\
    *.wmv=:\
    *.asf=:\
    *.rm=:\
    *.rmvb=:\
    *.flc=:\
    *.avi=:\
    *.fli=:\
    *.flv=:\
    *.gl=:\
    *.dl=:\
    *.xcf=:\
    *.xwd=:\
    *.yuv=:\
    *.cgm=:\
    *.emf=:\
    *.ogv=:\
    *.ogx=:\
    *.aac=:\
    *.au=:\
    *.flac=:\
    *.m4a=:\
    *.mid=:\
    *.midi=:\
    *.mka=:\
    *.mp3=:\
    *.mpc=:\
    *.ogg=:\
    *.ra=:\
    *.wav=:\
    *.oga=:\
    *.opus=:\
    *.spx=:\
    *.xspf=:\
    *.pdf=:\
    *.nix=:\
    "
  '';
}
