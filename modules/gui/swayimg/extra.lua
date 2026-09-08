local home = os.getenv("HOME")

swayimg.viewer.on_key("c", function()
    local img = swayimg.viewer.get_image()
    if img then
        run(string.format("nomacs %q &", img.path))
    end
end)

swayimg.viewer.on_key("w", function() -- w { command(wallpaper $1) }
    local img = swayimg.viewer.get_image()
    if img then
        run(string.format("wallpaper %q &", img.path))
    end
end)

swayimg.viewer.on_key("m", function()
    local img = swayimg.viewer.get_image()
    if img then
        run(string.format("mv %q %q", img.path, home .. "/Pictures/wallpapers_in"))
    end
end)

swayimg.viewer.on_key("Ctrl-m", function()
    local img = swayimg.viewer.get_image()
    if img then
        run(string.format("mv %q %q", img.path, home .. "/Pictures/wallpapers_crop"))
    end
end)

swayimg.gallery.on_key("c", function()
    local img = swayimg.gallery.get_image()
    if img then
        run(string.format("nomacs %q &", img.path))
    end
end)

swayimg.gallery.on_key("w", function()
    local img = swayimg.gallery.get_image()
    if img then
        run(string.format("wallpaper %q &", img.path))
    end
end)

swayimg.gallery.on_key("m", function()
    local img = swayimg.gallery.get_image()
    if img then
        run(string.format("mv %q %q", img.path, home .. "/Pictures/wallpapers_in"))
    end
end)

swayimg.gallery.on_key("Ctrl-m", function()
    local img = swayimg.gallery.get_image()
    if img then
        run(string.format("mv %q %q", img.path, home .. "/Pictures/wallpapers_crop"))
    end
end)
