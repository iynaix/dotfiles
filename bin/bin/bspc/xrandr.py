import re
import subprocess


class XRandR:
    def __init__(self, lines=None):
        display_re = r"""(?P<name>\S+)\s
        (?P<connected>disconnected|connected)\s
        (?P<primary>primary\s)?
        (?P<width>\d+)x(?P<height>\d+)"""

        if lines is None:
            lines = subprocess.check_output(["xrandr"], text=True).splitlines()

        self.displays = []
        for line in lines:
            res = re.match(display_re, line, re.VERBOSE)
            if res:
                res = res.groupdict()

                width = int(res["width"])
                height = int(res["height"])

                self.displays.append(
                    {
                        **res,
                        "bspwm_name": f"%{res['name']}"
                        if "." in res["name"]
                        else res["name"],
                        "connected": res["connected"] == "connected",
                        "primary": res["primary"] is not None,
                        "width": width,
                        "height": height,
                    }
                )

        # sort by largest display (pixel count)
        self.displays.sort(key=lambda d: d["width"] * d["height"], reverse=True)

    def __str__(self):
        return "\n".join(repr(d) for d in self.displays)

    def __iter__(self):
        return self.displays.__iter__()

    @property
    def connected(self):
        return [d for d in self.displays if d["connected"]]

    @property
    def disconnected(self):
        return [d for d in self.displays if not d["connected"]]

    @property
    def primary(self):
        for d in self.connected:
            if d["primary"]:
                return d

    @property
    def secondary(self):
        return [d for d in self.connected if not d["primary"]]

    def dim(self, x, y):
        return f"{x}x{y}"

    def xrandr_display_args(
        self,
        vertical=False,
        rotate="normal",
        x_offset=0,
        y_offset=0,
        primary=False,
        **kwargs,
    ):
        [w, h] = sorted((kwargs["width"], kwargs["height"]), reverse=True)
        args = [
            "--output",
            kwargs["name"],
            "--primary" if primary else "",
            "--mode",
            self.dim(w, h),
            "--pos",
            self.dim(x_offset, y_offset),
            "--rotate",
            rotate,
        ]
        return [a for a in args if a]


XRANDR_MONITORS = {}
ULTRAWIDE_NAME = None
VERTICAL_NAME = None


def mon_name(name):
    if "." in name:
        return f"%{name}"
    return name


### COMPUTE CONSTANTS ###

for mon in XRandR():
    XRANDR_MONITORS[mon["name"]] = mon

    if mon["width"] >= 3440:
        ULTRAWIDE_NAME = mon_name(mon["name"])
    if mon["width"] < mon["height"]:
        VERTICAL_NAME = mon_name(mon["name"])

ENVIRONMENT = "desktop" if ULTRAWIDE_NAME and VERTICAL_NAME else "laptop"
