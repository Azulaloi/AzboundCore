col = {}

-- A library of color conversion methods.
-- Warning: few to no safety checks, watch your args.
-- WIP, needs testing, etc.

------
-- Format Converters (Dex<->Hex)
------

-- Format Converter: String to Array
-- Takes a string, separates it into an array
function col.hexToArray(hexIn)
	local array = {}
	local length = string.len(hexIn)
	
	if type(hexIn) == string then
		if (length % 2 == 0) then
			for i = 1, (length/2) do
				array[i] = string.sub(hexIn, 
									  (1 + (2 * (i - 1))), 
									  (2 + (2 * (i - 1))) )
			end
			
			return array
		else
			-- it's not even, throw a fit
			return nil
		end
	else
		-- it's not a string, throw a fit
		return nil
	end
end

-- Format Converter: converts hex strings/arrays to an array of numbers 
-- Takes a string or array
--   String: will split string into hex values, and return array of three dec values
--   Array: will attempt to convert each value in the array to dec, and return array
function col.hexToNum(hexIn)
    local dexedhex = {}

	if type(hexIn) == "string" then
		local length = string.len(hexIn)
		
		-- should it just take an arbitrary length instead? the shorthex handler would have to be an additional arg in that case.
		if length == 6 then
			local h = { string.sub(hexIn, 1, 2),
						string.sub(hexIn, 3, 4),
						string.sub(hexIn, 5, 6) }
			
			for i = 1, 3 do
				dexedhex[i] = col.hexToDec(h[i])
			
				-- quantity-arbitrary implementation
				--table.insert(dexedhex, i, tonumber(string.sub(hex, 1 + (2 * (i - 1)), 2 + (2 * (i - 1))), 16))
			end
			
			return dexedhex
		elseif length == 3 then
			-- handle short hex
		else
			sb.logWarn("AzColourUtil: col.hexToNum() error")
			return nil
		end
	elseif type(hexIn) == "table" then -- moving this to hexArrayToNum
		for i, v in ipairs(hexIn) do
			if string.len(v) == 2 then
				dexedhex[i] = col.hexToDec(v)
			elseif string.len(v) == 6 then
				-- this isnt converting to dec
				dexedhex[i] = col.hexSplit(v)
			end
		end
		
		return dexedhex
	end
end

-- takes an array of arrays of hex strings and converts them to an array of arrays of numbers
function col.hexArrayToNum(hexIn)
	local hex = {}
	
	for i, v in ipairs(hexIn) do
		local h = {}
		
		for iter, val in ipairs(v) do
			h[iter] = col.hexToDec(val)
		end
		
		hex[i] = h
	end
	
	return hex
end

-- only does 6 length right now
-- turns a 6 length string into an array of three two length strings
function col.hexSplit(hexIn)
	if string.len(hexIn) == 6 then
		local h = { string.sub(hexIn, 1, 2),
					string.sub(hexIn, 3, 4),
					string.sub(hexIn, 5, 6) }
		return h
	else return nil end
end

-- takes an array of x 6 length strings
-- returns an array of x 3 length arrays of 2 length strings
function col.hexArraySplit(hexIn)
	local array = {}
	for i, v in ipairs(hexIn) do
		array[i] = col.hexSplit(v)
	end
	return array
end

-- Takes a hex string, returns a dec number, but with colour safety
-- Also converts short hex to long hex
function col.hexColToDec(hexIn)
	local length = string.length(hexIn)
	
	if length == 2 then
		return tonumber(hexIn, 16)
	elseif length == 1 then
		return tonumber(hexIn .. hexIn, 16)
	else
		sb.logWarn("AzColourUtil: col.hexToDec() failed to convert, returning nil! failed args: " .. tostring(hexIn))
		return nil
	end
end

-- Takes a hex string, returns a dec number
function col.hexToDec(hexIn)
	return tonumber(hexIn, 16)
end

-- Takes a dec number, returns a hex string
function col.decToHex(decIn) 
	return string.format("%x", decIn * 255)
end


------
-- Colorspace Converters
------

-- Colorspace Converter: RGB to HSL
-- Takes array of 3 nums {R, G, B}; returns array of 3 nums {H, S, L}
function col.rgbToHSL(rgbIn)
    local rgb = {0, 0, 0}
    for i, v in ipairs(rgbIn) do
        rgb[i] = rgbIn[i] / 255
    end

    local cmax = math.max(rgb[1], rgb[2], rgb[3])
    local cmin = math.min(rgb[1], rgb[2], rgb[3])
    local delta = cmax - cmin

	-- Hue Calculation
	local h = 0
    if delta == 0 then
        h = 0
    elseif cmax == rgb[1] then
        h = 60 * (((rgb[2] - rgb[3]) / delta) % 6)
    elseif cmax == rgb[2] then
        h = 60 * (((rgb[3] - rgb[1]) / delta) + 2)
    elseif cmax == rgb[3] then
        h = 60 * (((rgb[1] - rgb[2]) / delta) + 4)
    end

	-- Lightness Calculation
    local l = (cmax + cmin) / 2

	-- Saturation Calculation
	local s = 0
    if delta == 0 then
        s = 0
    elseif delta > 0 or delta < 0 then
        s = (delta / (1 - math.abs((2 * l) - 1)))
    end

    return {h, s, l}
end

-- Colorspace Converter: HSL to RGB
-- Takes array of 3 nums {H, S, L}; Returns array of 3 nums {R, G, B}
function col.hslToRGB(hslIn)
	local hsl = {0, 0, 0}
	hsl[1] = hslIn[1]
	hsl[2] = hslIn[2]
	hsl[3] = hslIn[3]

    local c = (1 - math.abs((2 * hsl[3]) -1)) * hsl[2]

    local x = c * (1 - math.abs((hsl[1]/60) % 2 - 1))

    local m = hsl[3] - c/2

    local rgbp = {}
    if 0 <= hsl[1] and hsl[1] < 60 then
        table.insert(rgbp, c)
        table.insert(rgbp, x)
        table.insert(rgbp, 0)
    elseif 60 <= hsl[1] and hsl[1] < 120 then
        table.insert(rgbp, x)
        table.insert(rgbp, c)
        table.insert(rgbp, 0)
    elseif 120 <= hsl[1] and hsl[1] < 180 then
        table.insert(rgbp, 0)
        table.insert(rgbp, c)
        table.insert(rgbp, x)
    elseif 180 <= hsl[1] and hsl[1] < 240 then
        table.insert(rgbp, 0)
        table.insert(rgbp, x)
        table.insert(rgbp, c)
    elseif 240 <= hsl[1] and hsl[1] < 300 then
        table.insert(rgbp, x)
        table.insert(rgbp, 0)
        table.insert(rgbp, c)
    elseif 300 <= hsl[1] and hsl[1] < 360 then
        table.insert(rgbp, c)
        table.insert(rgbp, 0)
        table.insert(rgbp, x)
    end

    local rgb = {}
    for k, v in ipairs(rgbp) do
        table.insert(rgb, (v+m) * 255)
    end

    return rgb
end

-- Colorspace Converter: RGB to HSV
-- Takes array of 3 nums {R, G, B}; returns array of 3 nums {H, S, V}
function col.rgbToHSV(rgbIn)
	local rgb = {0, 0, 0}
	for i, v in ipairs(rgbIn) do
		rgb[i] = rgbIn[i] / 255
	end
	
    local cmax = math.max(rgb[1], rgb[2], rgb[3])
    local cmin = math.min(rgb[1], rgb[2], rgb[3])
    local delta = cmax - cmin

	-- Hue Calculation
	local h = 0
    if delta == 0 then
        h = 0
    elseif cmax == rgb[1] then
        h = 60 * (((rgb[2] - rgb[3]) / delta) % 6)
    elseif cmax == rgb[2] then
        h = 60 * (((rgb[3] - rgb[1]) / delta) + 2)
    elseif cmax == rgb[3] then
        h = 60 * (((rgb[1] - rgb[2]) / delta) + 4)
    end
	
	-- Saturation Calculation
	local s = 0
	if cmax == 0 then
		s = 0
	else s = delta/cmax end
	
	-- Value "Calculation"
	local v = cmax
	
	return {h, s, v}
end

-- Colorspace Converter: HSV to RGB
-- Takes array of 3 nums {H, S, V}; returns array of 3 nums {R, G, B}
function col.hsvToRGB(hsv)
	local s = hsv[2]
	local v = hsv[3]
	
	local h = hsv[1]
	if h >= 360 then h = 0 end
	h = h / 60
	
	local i = math.floor(h)
	local f = h - i
	
	local p = v * (1 - s)
	local q = v * (1 - (s * f))
	local t = v * (1 - (s * (1 - f)))
	
	local case = {
		[0] = {v, t, p},
		[1] = {q, v, p},
		[2] = {p, v, t},
		[3] = {p, q, v},
		[4] = {t, p, v},
		[5] = {v, p, q}
	}
	
	local out = {}
	if case[i] then out = case[i] else out = {v, p, q} end
	return {out[1] * 255, out[2] * 255, out[3] * 255} 
end

-- Colorspace Converter: RGB to CYMK
-- Takes array of 3 nums {R, G, B}; returns array of 4 nums {C, Y, M, K}
function col.rgbToCYMK(rgbIn)
	local rgb = {
		rgbIn[1] / 255,
		rgbIn[2] / 255,
		rgbIn[3] / 255 }
		
	local k = 1 - math.max(rgb[1], rgb[2], rgb[3])
	local c = (1 - rgb[1] - k) / (1 - k)
	local m = (1 - rgb[2] - k) / (1 - k)
	local y = (1 - rgb[3] - k) / (1 - k)
	
	return {c, y, m, k}
end

-- Colorspace Converter: CYMK to RGB
-- Takes array of 4 nums {C, Y, M, K}; returns array of 3 nums {R, G, B}
function col.cymkToRGB(cymk)
	local r = 255 * (1 - cymk[1]) * (1 - cymk[4])
	local g = 255 * (1 - cymk[3]) * (1 - cymk[4])
	local b = 255 * (1 - cymk[2]) * (1 - cymk[4])
	
	return {r, g, b}
end

-- TODO: Col to hex for sake of completeness