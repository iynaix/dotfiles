import argparse
import json
import socket
import subprocess
import sys

ULTRAWIDE = "DP-2"
VERTICAL = "DP-4"
SMALL = "HDMI-A-1"

IS_DESKTOP = socket.gethostname().endswith("desktop")
USE_CENTERED_MASTER = False


def debug(*cmds, **kwargs):
    if DEBUG:
        print("[DEBUG]", *cmds, **kwargs)


def info(cmd):
    with subprocess.Popen(["hyprctl", "-j", cmd], stdout=subprocess.PIPE) as proc:
        return json.loads(proc.stdout.read())


def workspace_info(workspace):
    for wksp in info("workspaces"):
        if wksp["name"] == workspace:
            return wksp


def dispatch(*args):
    cmd = ["hyprctl", "dispatch", *args]
    if DEBUG:
        debug(cmd)
    else:
        subprocess.run(cmd)


def set_workspace_orientation(workspace, nstack):
    if not IS_DESKTOP:
        return

    wksp = workspace_info(workspace)

    if wksp["windows"]:
        if wksp["monitor"] == VERTICAL:
            dispatch("layoutmsg", "orientationtop")
        elif wksp["monitor"] == SMALL:
            dispatch("layoutmsg", "orientationleft")
        elif wksp["monitor"] == ULTRAWIDE:
            if USE_CENTERED_MASTER:
                dispatch("layoutmsg", "orientationcenter")

        if nstack:
            stacks = 2
            if wksp["monitor"] == VERTICAL or wksp["monitor"] == ULTRAWIDE:
                stacks = 3
            dispatch("layoutmsg", "setstackcount", str(stacks))


def parse_args():
    parser = argparse.ArgumentParser(
        prog="hypr-ipc", description="Hyprland IPC listener for workspace events"
    )

    parser.add_argument(
        "--debug",
        action="store_true",
        help="print unhandled events",
    )

    parser.add_argument(
        "--nstack",
        action="store_true",
        help="use nstack layout",
    )

    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    DEBUG = args.debug

    while 1:
        line = sys.stdin.readline()
        [ev, ev_args] = line.split(">>")
        ev_args = ev_args.strip().split(",")

        # print("[EVENT]", ev)
        if ev == "monitoradded":
            if IS_DESKTOP:
                subprocess.run("hypr-monitors")

            # always reset wallpaper and waybar
            # subprocess.run("hypr-wallpaper", stdout=subprocess.DEVNULL)

        elif ev == "monitorremoved":
            # focus workspace on ultrawide
            if IS_DESKTOP:
                dispatch("focusmonitor", ULTRAWIDE)

        # elif ev == "workspace":
        #     [workspace] = ev_args
        elif ev == "openwindow":
            [_, workspace, *_] = ev_args
            set_workspace_orientation(workspace, args.nstack)
        elif ev == "movewindow":
            [_, workspace] = ev_args
            set_workspace_orientation(workspace, args.nstack)
        # elif ev == "closewindow":
        #     [win_id] = ev_args
        # elif ev == "focusedmon":
        #     [mon, workspace] = ev_args

        else:
            debug(ev, ev_args)
