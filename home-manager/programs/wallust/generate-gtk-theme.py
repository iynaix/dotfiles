import json
import sys
from pathlib import Path


def hex_to_rgb(hex_str: str):
    # Convert hexadecimal color to RGB tuple
    hex_str = hex_str.lstrip("#")
    return tuple(int(hex_str[i : i + 2], 16) for i in (0, 2, 4))


def rgb_to_hex(rgb: tuple[int, int, int]):
    # Convert RGB tuple to hexadecimal color
    return f"#{rgb[0]:02x}{rgb[1]:02x}{rgb[2]:02x}"


def get_colors():
    try:
        return json.load(open(Path("~/.cache/wallust/colors.json").expanduser()))
    except FileNotFoundError:
        return {}


def s_prop(name: str, color: str):
    return f"${name}: {color};"


def s_section(name: str, *color_list: tuple[str, str]):
    out = f"\n// {name}\n"
    colors = "\n".join([s_prop(name, color) for name, color in color_list])
    return out + colors


def s_light_dark(name: str, light: str, dark: str):
    lname = name.lower()

    return s_section(
        name,
        (f"{lname}-light", light),
        (f"{lname}-dark", dark),
    )


def combine_colors(color1: str, color2: str):
    # Convert hexadecimal colors to RGB tuples
    rgb_color1 = hex_to_rgb(color1)
    rgb_color2 = hex_to_rgb(color2)

    # Combine the RGB components by addition
    combined_r = min(rgb_color1[0] + rgb_color2[0], 255)
    combined_g = min(rgb_color1[1] + rgb_color2[1], 255)
    combined_b = min(rgb_color1[2] + rgb_color2[2], 255)

    # Convert the combined RGB components back to hexadecimal
    return rgb_to_hex((combined_r, combined_g, combined_b))


def grayscale_stops(light, dark, num_stops):
    dark_rgb = hex_to_rgb(dark)
    light_rgb = hex_to_rgb(light)

    # Calculate the step size for each RGB component
    step_r = (light_rgb[0] - dark_rgb[0]) / (num_stops - 1)
    step_g = (light_rgb[1] - dark_rgb[1]) / (num_stops - 1)
    step_b = (light_rgb[2] - dark_rgb[2]) / (num_stops - 1)

    # Generate gradient stops
    gradient_stops = []
    for i in range(num_stops):
        r = int(dark_rgb[0] + step_r * i)
        g = int(dark_rgb[1] + step_g * i)
        b = int(dark_rgb[2] + step_b * i)

        # Convert RGB values back to hexadecimal
        hex_color = f"#{r:02x}{g:02x}{b:02x}"
        gradient_stops.append(hex_color)

    return gradient_stops


if __name__ == "__main__":
    if not sys.argv[1]:
        print("GTK theme template directory is required.")

    colors = get_colors()
    c = {int(k.replace("color", "")): v for k, v in colors["colors"].items()}

    black = colors["special"]["background"]
    white = colors["special"]["foreground"]

    #  0       1       2       3     4       5      6      7
    #  black, red, green, yellow, blue, magenta, cyan, white

    grays = []
    n = 50
    for gray in grayscale_stops(
        white,
        black,
        # ignore black and white
        19 + 2,
    )[1:-1]:
        grays.append((f"grey-{str(n).zfill(3)}", gray))
        n += 50

    out = [
        s_light_dark("Red", c[1], c[1 + 8]),
        s_light_dark("Pink", c[5], c[5 + 8]),
        s_light_dark(
            "Purple",
            combine_colors(c[1], c[4]),
            combine_colors(c[1 + 8], c[4 + 8]),
        ),
        s_light_dark("Blue", c[4], c[4 + 8]),
        s_light_dark("Teal", c[6], c[6 + 8]),
        s_light_dark("Green", c[2], c[2 + 8]),
        s_light_dark("Yellow", c[3], c[3 + 8]),
        s_light_dark(
            "Orange",
            combine_colors(c[1], c[3]),
            combine_colors(c[1 + 8], c[3 + 8]),
        ),
        s_section("Grey", *grays),
        s_section("White", ("white", white)),
        s_section("Black", ("black", black)),
        s_section(
            "Button",
            ("button-close", c[1]),
            ("button-max", c[2]),
            ("button-min", c[3]),
        ),
        s_section(
            "Theme",
            ("default-light", "$blue-light"),
            ("default-dark", "$blue-dark"),
        ),
    ]

    default_scss = sys.argv[1]
    with open(default_scss, "w") as f:
        f.write("// Generated Theme Color Palette\n")
        f.write("\n".join(out))
