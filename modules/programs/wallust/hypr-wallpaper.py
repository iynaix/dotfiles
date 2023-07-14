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


def set_hyprland_colors(colors):
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


parser = argparse.ArgumentParser(
    prog="hypr-wallpaper",
    description="Changes the wallpaper and updates the colorscheme",
)


# --rofi?
def get_wallust_preset_themes():
    with subprocess.Popen(
        ["wallust-themes", "theme", "--help"], stdout=subprocess.PIPE
    ) as proc:
        # get longest line in the output
        line = sorted(proc.stdout.read().splitlines(), key=len)[-1]
        line = line.decode("utf-8").split(" values: ")[-1].replace("]", "")
        return line.split(", ")


preset_themes = get_wallust_preset_themes()

parser.add_argument("--reload", action="store_true", help="reload the wallpaper")
parser.add_argument(
    "--transition-type",
    help="transition type for swww",
    default="random",
)
parser.add_argument(
    "--theme",
    help="preset theme for wallust",
    choices=preset_themes,
)
parser.add_argument("image", help="path to the wallpaper image", nargs="?")


if __name__ == "__main__":
    args = parser.parse_args()

    wallpaper = args.image or random_wallpaper()

    # generate colors
    if args.theme:
        run(["wallust-themes", "theme", args.theme])
    else:
        run(["wallust", wallpaper])

    colors = get_colors()
    set_hyprland_colors(colors)

    # set the wallpaper
    if not (args.reload or args.theme):
        run(["swww", "img", "--transition-type", args.transition_type, wallpaper])

    # reload waybar
    run(["killall", "-SIGUSR2", ".waybar-wrapped"])
