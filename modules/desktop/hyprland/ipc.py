import json
import sys
import subprocess

ULTRAWIDE = "DP-2"
VERTICAL = "DP-4"
SMALL = "HDMI-A-1"

DEBUG = False

def info(cmd):
    with subprocess.Popen(["hyprctl", "-j", cmd], stdout=subprocess.PIPE) as proc:
        return json.loads(proc.stdout.read())

IS_DESKTOP = set([m["name"] for m in info("monitors")]) == {ULTRAWIDE, VERTICAL, SMALL}

def workspace_info(workspace):
    for wksp in info("workspaces"):
        if wksp["name"] == workspace:
            return wksp

def dispatch(*args):
    cmd = ["hyprctl", "dispatch", *args]
    if DEBUG:
        print("[DEBUG]", cmd)
    subprocess.run(cmd)

def set_workspace_orientation(workspace):
    if not IS_DESKTOP:
        return

    wksp = workspace_info(workspace)

    if wksp["windows"] > 1:
        if wksp["monitor"] == VERTICAL:
            dispatch("layoutmsg", "orientationtop")
        elif wksp["monitor"] == SMALL:
            dispatch("layoutmsg", "orientationleft")


if __name__ == "__main__":
    while 1:
        line = sys.stdin.readline()
        [ev, ev_args] = line.split(">>")
        ev_args = ev_args.strip().split(",")

        # print("[EVENT]", ev)
        if ev == "monitoradded":
            if IS_DESKTOP:
                subprocess.run("hypr-reset-monitors")

            # always reset wallpaper and waybar
            subprocess.run("hypr-wallpaper", stdout=subprocess.DEVNULL)
            subprocess.run("launch-waybar", stdout=subprocess.DEVNULL)


        elif ev == "monitorremoved":
            # reset wallpaper
            subprocess.run("hypr-wallpaper", stdout=subprocess.DEVNULL)

            # focus workspace on ultrawide
            if IS_DESKTOP:
                dispatch("focusmonitor", ULTRAWIDE)

        # elif ev == "workspace":
        #     [workspace] = ev_args
        elif ev == "openwindow":
            [win_id, workspace, *_] = ev_args
            set_workspace_orientation(workspace)
        elif ev == "movewindow":
            [win_id, workspace] = ev_args
            set_workspace_orientation(workspace)
        # elif ev == "closewindow":
        #     [win_id] = ev_args
        # elif ev == "focusedmon":
        #     [mon, workspace] = ev_args

        else:
            # print(ev, ev_args)
            pass