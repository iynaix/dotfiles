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
        return {}


def get_current_wallpaper():
    curr = dict.get(get_colors(), "wallpaper", None)

    if curr and curr != "./foo/bar.txt":
        return curr

    # set using theme, use swww to get the wallpaper
    with subprocess.Popen(["swww", "query"], stdout=subprocess.PIPE) as proc:
        line = proc.stdout.read().splitlines()[0].decode("utf-8")
        img = line.split(": ").pop().replace('"', "")
        return str(WALLPAPERS / img)


def random_wallpaper():
    curr = get_current_wallpaper()
    wallpapers = []

    for f in WALLPAPERS.iterdir():
        if f.is_file() and f.suffix in [".jpg", ".jpeg", ".png"]:
            if f == curr:
                continue
            wallpapers.append(f)

    return random.choice(wallpapers)


def refresh_zathura():
    # get list of all dbus destinations
    with subprocess.Popen(
        [
            "dbus-send",
            "--print-reply",
            "--dest=org.freedesktop.DBus",
            "/org/freedesktop/DBus",
            "org.freedesktop.DBus.ListNames",
        ],
        stdout=subprocess.PIPE,
    ) as proc:
        for line in proc.stdout.read().decode("utf-8").splitlines():
            if "org.pwmt.zathura" in line:
                dest = sorted(line.strip().split('"'), key=len)[-1]
                # send message to zathura via dbus
                run(
                    [
                        "dbus-send",
                        "--type=method_call",
                        f"--dest={dest}",
                        "/org/pwmt/zathura",
                        "org.pwmt.zathura.ExecuteCommand",
                        "string:source",
                    ]
                )
                return


def set_colors():
    colors = get_colors()

    if not colors:
        return

    # get hexless colors
    c = {
        int(k.replace("color", "")): f"rgb({v.replace('#', '')})"
        for k, v in colors["colors"].items()
    }

    # update borders
    run(["hyprctl", "keyword", "general:col.active_border", f"{c[4]} {c[0]} 45deg"])
    run(["hyprctl", "keyword", "general:col.inactive_border", c[0]])

    # pink border for monocle windows
    run(["hyprctl", "keyword", "windowrulev2", "bordercolor", f"{c[5]},fullscreen:1"])
    # teal border for floating windows
    run(["hyprctl", "keyword", "windowrulev2", "bordercolor", f"{c[6]},floating:1"])
    # yellow border for sticky (must be floating) windows
    run(["hyprctl", "keyword", "windowrulev2", "bordercolor", f"{c[3]},pinned:1"])

    # refresh zathura
    refresh_zathura()

    # refresh cava
    run(["killall", "-SIGUSR2", "cava"])

    # refresh waifufetch
    run(["killall", "-SIGUSR2", "python3"])

    # refresh waybar
    run(["killall", "-SIGUSR2", ".waybar-wrapped"])


def get_wallust_preset_themes():
    with subprocess.Popen(
        ["wallust", "theme", "--help"], stdout=subprocess.PIPE
    ) as proc:
        # get longest line in the output
        line = sorted(proc.stdout.read().splitlines(), key=len)[-1]
        line = line.decode("utf-8").split(" values: ")[-1].replace("]", "")
        return line.split(", ")


PRESET_THEMES = get_wallust_preset_themes()
CUSTOM_THEMES = [
    "catppuccin-frappe",
    "catppuccin-macchiato",
    "catppuccin-mocha",
    "night-owl",
    "tokyo-night",
]
THEMES = sorted(PRESET_THEMES + CUSTOM_THEMES)


def apply_theme(theme: str):
    if theme in CUSTOM_THEMES:
        run(
            [
                "wallust",
                "cs",
                str(Path(f"~/.config/wallust/{theme}.json").expanduser()),
            ]
        )
    else:
        run(["wallust", "theme", theme])


def swww(*args: str):
    # check if swww is initialized and init if needed
    with subprocess.Popen(
        ["swww", "query"], stdout=subprocess.PIPE, stderr=subprocess.PIPE
    ) as proc:
        # not started
        if proc.stderr.read().decode("utf-8").startswith("Error"):
            # FIXME: weird race condition with swww init, need to sleep for a second
            # https://github.com/Horus645/swww/issues/144
            run(
                ["sleep 1; swww init", "&&", "swww", *args],
                shell=True,
            )
        else:
            run(["swww", *args])


def rofi_theme():
    rofi_process = subprocess.Popen(
        ["rofi", "-dmenu"], stdin=subprocess.PIPE, stdout=subprocess.PIPE
    )
    theme, _ = rofi_process.communicate(input="\n".join(THEMES).encode())

    apply_theme(theme.decode("utf-8").strip())
    set_colors()


def rofi_wallpaper():
    count = 0

    for f in WALLPAPERS.iterdir():
        if f.is_file() and f.suffix in [".jpg", ".jpeg", ".png"]:
            count += 1

    float_rule = "[float;size 30%;center]"
    # to behave like rofi
    esc_bind = "bind <Escape> quit"
    rand_idx = random.randint(1, count)
    run(
        [
            "hyprctl",
            "dispatch",
            "exec",
            f"{float_rule} imv -n {rand_idx} -c '{esc_bind}' {str(WALLPAPERS)}",
        ]
    )


def parse_args():
    parser = argparse.ArgumentParser(
        prog="hypr-wallpaper",
        description="Changes the wallpaper and updates the colorscheme",
    )

    parser.add_argument("--reload", action="store_true", help="reload the wallpaper")
    parser.add_argument(
        "--transition-type",
        help="transition type for swww",
        default="random",
        choices=[
            "simple",
            "fade",
            "left",
            "right",
            "top",
            "bottom",
            "wipe",
            "wave",
            "grow",
            "center",
            "any",
            "random",
            "outer",
        ],
    )
    parser.add_argument(
        "--theme",
        help="preset theme for wallust",
        choices=THEMES,
    )
    parser.add_argument(
        "--rofi",
        help="use rofi to select a wallpaper / theme",
        choices=["wallpaper", "theme"],
    )
    parser.add_argument("image", help="path to the wallpaper image", nargs="?")

    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()

    if args.rofi == "theme":
        rofi_theme()
        exit()

    if args.rofi == "wallpaper":
        rofi_wallpaper()
        exit()

    wallpaper = args.image or random_wallpaper()

    # set colors and wallpaper
    if args.theme:
        apply_theme(args.theme)
    elif args.reload:
        wall = get_current_wallpaper() or wallpaper
        run(["wallust", wall])
        swww("img", wall)
    else:
        run(["wallust", wallpaper])
        swww("img", "--transition-type", args.transition_type, wallpaper)

    set_colors()
