col = {}

-- A library of color conversion methods.
-- Warning: few to no safety checks, watch your args.
-- WIP, needs testing, etc.

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

-- Colorspace Converter: RGB to HSL
-- Takes array of 3 floats {R, G, B}
-- Returns array of 3 floats {H, S, L}
function col.rgbToHSL(rgbIn)
    rgb = {0, 0, 0}
    for k, v in ipairs(rgbIn) do
        rgb[k] = rgbIn[k] / 255
    end

    cmax = math.max(rgb[1], rgb[2], rgb[3])
    cmin = math.min(rgb[1], rgb[2], rgb[3])
    delta = cmax - cmin

    if delta == 0 then
        h = 0
    elseif cmax == rgb[1] then
        h = 60 * (((rgb[2] - rgb[3]) / delta) % 6)
    elseif cmax == rgb[2] then
        h = 60 * (((rgb[3] - rgb[1]) / delta) + 2)
    elseif cmax == rgb[3] then
        h = 60 * (((rgb[1] - rgb[2]) / delta) + 4)
    end

    l = (cmax + cmin) / 2

    if delta == 0 then
        s = 0
    elseif delta > 0 or delta < 0 then
        s = (delta / (1 - math.abs((2 * l) - 1)))
    end

    hsl = {h, s, l}

    return hsl
end

-- Colorspace Converter: HSL to RGB
-- Takes array of 3 floats {H, S, L}
-- Returns array of 3 floats {R, G, B}
function col.hslToRGB(hslIn)
	hsl = {0, 0, 0}
	hsl[1] = hslIn[1]
	hsl[2] = hslIn[2]
	hsl[3] = hslIn[3]

    c = (1 - math.abs((2 * hsl[3]) -1)) * hsl[2]

    x = c * (1 - math.abs((hsl[1]/60) % 2 - 1))

    m = hsl[3] - c/2

    rgbp = {}
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

    rgb = {}
    for k, v in ipairs(rgbp) do
        table.insert(rgb, (v+m) * 255)
    end

    return rgb
end

-- RGB/HSL to hex for sake of completeness