local M = {}

function starts_with(str, start) return string.sub(str, 1, #start) == start end

function shallow_copy(tbl)
	local copy = {}
	for k, v in pairs(tbl) do
		copy[k] = v
	end
	return copy
end

function resolve(colors)
	colors = shallow_copy(colors)
	local out = {}

	while next(colors) do
		local didProcess = false
		for key, value in pairs(colors) do
			if starts_with(value, "#") then
				out[key] = value
				colors[key] = nil
				didProcess = true
			elseif out[value] then
				out[key] = out[value]
				colors[key] = nil
				didProcess = true
			end
		end

		if not didProcess then
			for key, value in pairs(colors) do
				out[key] = out.error or colors.error
				colors[key] = nil
			end
		end
	end

	return out
end

function M.get_palette(flavour)
	local flvr = flavour or require("catppuccin").flavour or vim.g.catppuccin_flavour or "mocha"
	local _, palette = pcall(require, "catppuccin.palettes." .. flvr)
	local O = require("catppuccin").options
	local ans = vim.tbl_deep_extend("keep", O.color_overrides.all or {}, O.color_overrides[flvr] or {}, palette or {})

	ans = resolve(ans)
	-- print(vim.inspect(ans))

	--[[ 
		Kitty makes Neovim transparent if its own terminal background matches Neovim, 
		so we need to adjust the color channels to make sure people don't suddenly
		have a transparent background if they haven't specified it.

		Unfortunately, this currently means all users on Kitty will have all their
		palette colors slightly offset.

		ref: https://github.com/kovidgoyal/kitty/issues/2917
	--]]
	if O.kitty then
		for accent, hex in pairs(ans) do
			local red_green_string = hex:sub(1, 5)
			local blue_value = tonumber(hex:sub(6, 7), 16)

			-- Slightly increase or decrease brightness of the blue channel
			blue_value = blue_value == 255 and blue_value - 1 or blue_value + 1
			ans[accent] = string.format("%s%.2x", red_green_string, blue_value)
		end
	end

	return ans
end

return M
