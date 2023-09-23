from pathlib import Path
from subprocess import run
import argparse
import json
import os
import signal
import sys


# creates the image and returns the path to the image
def create_image(colors=None):
    if not colors:
        colors = json.load(open(Path("~/.cache/wallust/nix.json").expanduser()))
    logo = colors["neofetch"]["logo"]
    c4 = colors["colors"]["color4"]
    c6 = colors["colors"]["color6"]

    img = f"/tmp/waifufetch-{c4}-{c6}.png".replace("#", "")

    run(
        [
            "magick",
            logo,
            # replace color 1
            "-fuzz",
            "10%",
            "-fill",
            c4,
            "-opaque",
            "#5278c3",
            # replace color 2
            "-fuzz",
            "10%",
            "-fill",
            c6,
            "-opaque",
            "#7fbae4",
            img,
        ]
    )

    return img


def waifufetch():
    colors = json.load(open(Path("~/.cache/wallust/nix.json").expanduser()))
    neofetch_config = colors["neofetch"]["conf"]
    img = create_image(colors)

    run(
        [
            "neofetch",
            "--kitty" if os.environ["TERM"] == "xterm-kitty" else "--sixel",
            img,
            "--config",
            neofetch_config,
        ]
    )


def parse_args():
    parser = argparse.ArgumentParser(
        prog="waifufetch",
        description="Neofetch with more waifu",
    )
    parser.add_argument(
        "--image", action="store_true", help="returns path to generated image"
    )

    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()

    if args.image:
        print(create_image())
        exit()

    def sigusr2_handler(sig, frame):
        waifufetch()

    def sigint_handler(sig, frame):
        sys.exit()

    # initial run
    waifufetch()

    # reload waifufetch on SIGUSR2
    signal.signal(signal.SIGUSR2, sigusr2_handler)
    # ctrl + c
    signal.signal(signal.SIGINT, sigint_handler)

    # keep process alive
    while True:
        pass
