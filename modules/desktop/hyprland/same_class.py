import json
import argparse
import subprocess


parser = argparse.ArgumentParser(description="Switches to the next or previous window of the same class.")
parser.add_argument('direction', type=str,
                    help='next or prev')


def info(cmd):
    with subprocess.Popen(["hyprctl", "-j", cmd], stdout=subprocess.PIPE) as proc:
        return json.loads(proc.stdout.read())


if __name__ == "__main__":
    args = parser.parse_args()

    direction = args.direction.lower().strip()

    if direction not in ("next", "prev"):
        print("Invalid direction, must be 'next' or 'prev'")
        raise SystemExit(1)

    active = info("activewindow")

    same_class = []

    for win in info("clients"):
        if win["class"] == active["class"]:
            same_class.append(win)

    # sort by workspace, then coordinates
    addresses = [w["address"] for w in sorted(same_class, key=lambda w: (w["workspace"]["id"], w["at"]))]
    idx = addresses.index(active["address"])

    if direction == "next":
        to_focus = addresses[(idx + 1) % len(addresses)]
    else:
        to_focus = addresses[idx - 1]

    subprocess.run(["hyprctl", "dispatch", "focuswindow", f"address:{to_focus}"])