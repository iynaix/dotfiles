import json
import subprocess


def info(cmd):
    with subprocess.Popen(["hyprctl", "-j", cmd], stdout=subprocess.PIPE) as proc:
        return json.loads(proc.stdout.read())


def dispatch(*args):
    subprocess.run(["hyprctl", "dispatch", *args])


if __name__ == "__main__":
    win = info("activewindow")
    # pprint(win)
    curr_mon = None

    for mon in info("monitors"):
        if mon["id"] == win["monitor"]:
            curr_mon = mon
            break

    # figure out dimensions of target window with aspect ratio 16:9
    target_w = int(0.2 * curr_mon["width"])
    target_h = int(target_w / 16.0 * 9)

    dispatch("fakefullscreen")
    dispatch("togglefloating", "active")
    dispatch("pin", "active")

    if not win["floating"]:
        # resize and move window to bottom corner
        dispatch("resizeactive", "exact", str(target_w), str(target_h))
        win = info("activewindow")

        padding = 30  # distance from the corner of the screen
        # check for vertical monitor
        if curr_mon["transform"] in (1, 3, 5, 7):
            mon_bottom = curr_mon["y"] + curr_mon["width"]
            mon_right = curr_mon["x"] + curr_mon["height"]
        else:
            mon_bottom = curr_mon["y"] + curr_mon["height"]
            mon_right = curr_mon["x"] + curr_mon["width"]

        delta_x = mon_right - padding - target_w - win["at"][0]
        delta_y = mon_bottom - padding - target_h - win["at"][1]

        dispatch("moveactive", str(delta_x), str(delta_y))
    else:
        # reset the border
        dispatch("fullscreen", "0")
        dispatch("fullscreen", "0")
