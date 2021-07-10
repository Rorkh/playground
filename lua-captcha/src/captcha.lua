local vips = require "vips"

local captcha = {}
captcha.__index = captcha

--function captcha.random_background()
--end

function captcha:new(text, options)
	options = options or {}

	local obj = {}
	setmetatable(obj, captcha)
	
	obj.text = text
	obj.options = options

	return obj
end

local function turbulence(turb_size)
    local image
    local iterations = math.log(turb_size, 2) - 2
    for i = 0, iterations do
        -- make perlin noise at this scale
        local layer = vips.Image.perlin(turb_size, turb_size, {
            cell_size = turb_size / math.pow(2, i)
        })
        layer = layer:abs() * (1.0 / (i + 1))

        -- and sum
        if image then
            image = image + layer
        else
            image = layer
        end
    end

    return image
end

local function gradient(start, stop)
    local lut = vips.Image.identity() / 255
    lut = lut * start + (lut * -1 + 1) * stop
    return lut:colourspace("srgb", { source_space = "lab" })
end

function captcha:save(filename)
	local image = vips.Image.text(self.text, {
		dpi = 300,

		font = self.options.font,
		fontfile = self.options.fontfile,

		width = self.options.width,
		height = self.options.height,
	})

	local background = vips.Image.xyz(image:width(), image:height()):extract_band(0)
	background = (background * 360 * 4 / image:width() + turbulence(image:width()) * 700):sin()

	-- make a colour map ... we want a smooth gradient from white to dark brown
	-- colours here in CIELAB
	local dark_brown = { 7.45, 4.3, 8 }
	local white = { 100, 0, 0 }
	local lut = gradient(dark_brown, white)

	-- rescale to 0 - 255 and colour with our lut
	background = ((background + 1) * 128):maplut(lut)
	image = image .. background

	image:write_to_file(filename, { compression = 1 })
end

return captcha
