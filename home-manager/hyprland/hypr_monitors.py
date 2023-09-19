import argparse
import json
import subprocess
from collections import defaultdict
from pathlib import Path
from typing import DefaultDict


def dispatch(*args: str):
    cmd = ["hyprctl", "dispatch", *args]
    subprocess.run(cmd)


def monitor_info():
    with subprocess.Popen(
        ["hyprctl", "-j", "monitors"], stdout=subprocess.PIPE
    ) as proc:
        return json.loads(proc.stdout.read())


def parse_args():
    parser = argparse.ArgumentParser(
        prog="hypr-monitors",
        description="Sets up workspace configuration for monitors",
    )

    parser.add_argument(
        "--displays",
        help="JSON string of display configuration from nix",
    )

    parser.add_argument(
        "--persistent-workspaces",
        action="store_true",
        help="Updates waybar config with persistent workspaces",
    )

    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()

    if not args.displays:
        print("No display configuration provided")
        exit(1)

    active_monitors = {
        m["name"]: m.get("activeWorkspace", {}).get("id") for m in monitor_info()
    }
    if not active_monitors:
        print("No active monitors")
        exit(1)

    displays = json.loads(args.displays)
    # pprint(displays)

    workspaces: DefaultDict[str, list[int]] = defaultdict(list)
    for i, display in enumerate(displays):
        name = display["name"]
        if name in active_monitors:
            workspaces[name].extend(display["workspaces"])
        else:
            # add to the other monitors if available
            for j, other_display in enumerate(displays):
                if i == j:
                    continue
                other_name = other_display["name"]
                if other_name in active_monitors:
                    workspaces[other_name].extend(display["workspaces"])
                    break

    # move workspaces to monitors
    for monitor, wksps in workspaces.items():
        for wksp in wksps:
            dispatch("moveworkspacetomonitor", str(wksp), monitor)

    # focus workspaces on monitors
    primary_workspaces = {1, 7, 9}
    for monitor, wksps in workspaces.items():
        # focus current workspace if monitor is already available
        # if current_wksp := active_monitors.get(monitor):
        #     dispatch("workspace", str(current_wksp))
        #     continue

        for wksp in wksps:
            if wksp in primary_workspaces:
                dispatch("workspace", str(wksp))
                break

    # focus first / primary monitor
    dispatch("focusmonitor", list(workspaces.keys())[0])

    # refresh wallpapers
    subprocess.run(["hypr-wallpaper", "--reload"])

    # add persistent workspaces to waybar config before relaunching waybar
    if args.persistent_workspaces:
        waybar_cfg = Path("~/.cache/wallust/waybar.jsonc").expanduser()
        with open(waybar_cfg, "r+") as f:
            cfg = defaultdict(dict)
            cfg.update(json.load(f))
            cfg["hyprland/workspaces"]["persistent-workspaces"] = workspaces

            # write cfg to file
            f.seek(0)
            f.write(json.dumps(cfg))

    subprocess.run(["launch-waybar"])
