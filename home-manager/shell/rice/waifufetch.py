from pathlib import Path
from subprocess import run
import json
import os
import signal
import sys


def waifufetch():
    colors = json.load(open(Path("~/.cache/wallust/colors.json").expanduser()))
    logo = colors["neofetch"]["logo"]
    neofetch_config = colors["neofetch"]["conf"]
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

    run(
        [
            "neofetch",
            "--kitty" if os.environ["TERM"] == "xterm-kitty" else "--sixel",
            img,
            "--config",
            neofetch_config,
        ]
    )


def sigusr2_handler(sig, frame):
    waifufetch()


def sigint_handler(sig, frame):
    sys.exit()


if __name__ == "__main__":
    # initial run
    waifufetch()

    # reload waifufetch on SIGUSR2
    signal.signal(signal.SIGUSR2, sigusr2_handler)
    # ctrl + c
    signal.signal(signal.SIGINT, sigint_handler)

    # keep process alive
    while True:
        pass
