from pathlib import Path
from subprocess import run
import argparse
import json
import random
import subprocess

WALLPAPERS = Path("~/Pictures/Wallpapers").expanduser()


def get_colors():
    try:
        return json.load(open(Path("~/.cache/wallust/colors.json").expanduser()))
    except FileNotFoundError:
        return None


def get_current_wallpaper():
    return getattr(get_colors(), "wallpaper", None)


def random_wallpaper():
    curr = get_current_wallpaper()
    wallpapers = []

    for f in WALLPAPERS.iterdir():
        if f.is_file() and f.suffix in [".jpg", ".jpeg", ".png"]:
            if f == curr:
                continue
            wallpapers.append(f)

    return random.choice(wallpapers)


def set_colors():
    colors = get_colors()

    # get hexless colors
    c = {
        int(k.replace("color", "")): f"rgb({v.replace('#', '')})"
        for k, v in colors["colors"].items()
    }

    # update borders
    run(
        [
            "hyprctl",
            "keyword",
            "general:col.active_border",
            f"{c[4]} {c[0]} 45deg",
        ]
    )
    run(["hyprctl", "keyword", "general:col.inactive_border", c[0]])

    # pink border for monocle windows
    run(["hyprctl", "keyword", "windowrulev2", "bordercolor", f"{c[5]},fullscreen:1"])
    # teal border for floating windows
    run(["hyprctl", "keyword", "windowrulev2", "bordercolor", f"{c[6]},floating:1"])
    # yellow border for sticky (must be floating) windows
    run(["hyprctl", "keyword", "windowrulev2", "bordercolor", f"{c[3]},pinned:1"])

    # reload waybar
    run(["killall", "-SIGUSR2", ".waybar-wrapped"])


parser = argparse.ArgumentParser(
    prog="hypr-wallpaper",
    description="Changes the wallpaper and updates the colorscheme",
)


def get_wallust_preset_themes():
    with subprocess.Popen(
        ["wallust-themes", "theme", "--help"], stdout=subprocess.PIPE
    ) as proc:
        # get longest line in the output
        line = sorted(proc.stdout.read().splitlines(), key=len)[-1]
        line = line.decode("utf-8").split(" values: ")[-1].replace("]", "")
        return line.split(", ")


PRESET_THEMES = get_wallust_preset_themes()


def rofi_theme():
    rofi_process = subprocess.Popen(
        ["rofi", "-dmenu"], stdin=subprocess.PIPE, stdout=subprocess.PIPE
    )
    theme, _ = rofi_process.communicate(input="\n".join(PRESET_THEMES).encode())

    run(["wallust-themes", "theme", theme.decode("utf-8").strip()])
    set_colors()


parser.add_argument("--reload", action="store_true", help="reload the wallpaper")
parser.add_argument(
    "--transition-type",
    help="transition type for swww",
    default="random",
)
parser.add_argument(
    "--theme",
    help="preset theme for wallust",
    choices=PRESET_THEMES,
)
parser.add_argument(
    "--rofi",
    help="use rofi to select a wallpaper / theme",
    choices=("wallpaper", "theme"),
)
parser.add_argument("image", help="path to the wallpaper image", nargs="?")


if __name__ == "__main__":
    args = parser.parse_args()

    if args.rofi == "theme":
        rofi_theme()
        exit()

    if args.rofi == "wallpaper":
        exit()

    wallpaper = args.image or random_wallpaper()

    # set colors and wallpaper
    if args.theme:
        run(["wallust-themes", "theme", args.theme])
    elif args.reload:
        run(["wallust", wallpaper])
    else:
        run(["wallust", wallpaper])
        run(["swww", "img", "--transition-type", args.transition_type, wallpaper])

    set_colors()