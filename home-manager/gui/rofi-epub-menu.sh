    epubs=$(fd -e=epub . ~/Books/)
    IFS="
    "
    open() {
      file=$(cat -)
      echo "$file"
      [[ -n "$file" ]] && zathura "$file.epub"
    }
    for i in $epubs; do
      image="$(dirname "$i")/cover.png"
      echo -en "${i%.epub}\0icon\x1f$image\n"
    done | rofi -i -dmenu -display-column-separator "/" -display-columns 7  -p " " -theme-str 'icon-current-entry { size: 100%;}' | open
