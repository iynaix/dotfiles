swayimg.mode = "viewer"
swayimg.decoration = false

swayimg.text.visible = false -- hide info box
swayimg.text.timeout = 86400 -- never hide the text
swayimg.text.size = 14
swayimg.text.color = 0xffffffff
swayimg.text.background = 0x00000000

swayimg.viewer.text = {
    topleft = {
        "{path} ({frame.width}x{frame.height}) {scale} [{list.index}/{list.total}]"
    },
    topright = {},
    bottomleft = {},
}

swayimg.imagelist.fsmon = true
swayimg.imagelist.order = "numeric"
swayimg.imagelist.recursive = false

local function run(cmd)
    os.execute(cmd)
end

----------------------
-- Viewer Mode
----------------------

swayimg.on_redrawn(function()
    if swayimg.mode == "viewer" then
        swayimg.viewer.set_fix_scale("fit")
    end
end)

swayimg.viewer.on_key("t", function()
    swayimg.mode = "gallery"
end)

swayimg.viewer.on_key("Left", function()
    swayimg.viewer.open("prev")
end)
swayimg.viewer.on_key("Right", function()
    swayimg.viewer.open("next")
end)

swayimg.viewer.on_key("Up", function() end) -- nop
swayimg.viewer.on_key("Down", function() end) -- nop

-- info bar
swayimg.viewer.on_key("i", function()
    swayimg.text.visible = !swayimg.text.visible
end)

-- change background to be able to see black / white bars for cropping
local current_bg = 0xff000000
swayimg.viewer.on_key("n", function()
    if current_bg == 0xff000000 then
        current_bg = 0xffff00ff
    else
        current_bg = 0xff000000
    end
    swayimg.viewer.set_window_background(current_bg)
end)

-- delete image
swayimg.viewer.on_key("x", function()
    local img = swayimg.viewer.get_image()
    if img then
        os.remove(img.path)
    end
end)

-- toggle random
swayimg.viewer.on_key("s", function()
    if swayimg.imagelist.order == "random" then
        swayimg.imagelist.order = "numeric"
    else
        swayimg.imagelist.order = "random"
    end
end)

swayimg.viewer.on_key("y", function()
    local img = swayimg.viewer.get_image()
    if img then
        run(string.format("wl-copy %q", img.path))
    end
end)

----------------------
-- Gallery / Montage mode
----------------------

swayimg.gallery.on_key("t", function()
    swayimg.mode = "viewer"
end)

swayimg.gallery.on_key("x", function()
    local img = swayimg.gallery.get_image()
    if img then
        os.remove(img.path)
    end
end)

swayimg.gallery.on_key("y", function()
    local img = swayimg.gallery.get_image()
    if img then
        run(string.format("wl-copy %q", img.path))
    end
end)
