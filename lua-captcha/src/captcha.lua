local vips = require "vips"

local captcha = {}
captcha.__index = captcha

function captcha:new(text, options)
	options = options or {}

	local obj = {}
	setmetatable(obj, captcha)
	
	obj.text = text
	obj.options = options

	return obj
end

function captcha:save(filename)
	local image = vips.Image.text(self.text, {dpi = 300, font = self.options.font, width = self.options.width, height = self.options.height})
	image:write_to_file(filename, { compression = 1 })
end

return captcha
