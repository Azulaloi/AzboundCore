prt = {}

-- Library of functions for working with portraits.
-- Some functions require access to world table.

-- Gets portrait with extancy check
function prt.extractPortrait(pid)
	if world.entityExists(pid) then
		return world.entityPortrait(pid, "full")
	else 
		sb.logError("AzPortraitUtil: entity <" .. tostring(pid) .. "> does not exist, returning nil")
		return nil 
	end
end

-- returns a specific image from a portrait
-- if arg boo is true, then treats arg pid as portrait instead of getting it again
function prt.extractImage(pid, str, boo)
	local image = nil
	
	local portrait = {}
	
	if boo then portrait = pid
	else portrait = prt.extractPortrait(pid) end

    for k, v in pairs(portrait) do
        if string.find(portrait[k].image, str) then
            image = portrait[k].image
        end
    end
	
	return image
end

-- takes an id or portrait and returns the brand image, will only work on novakid portraits
-- to use a portrait, pass (portrait, true)
-- TODO: remove masking
function prt.extractBrand(pid, boo)
	local brand = prt.extractImage(pid, "/humanoid/novakid/brand/", boo)
	brand = sb.printJson(brand)
	brand = brand:sub(2)
	brand = brand:sub(0, #brand-1)
	
	return brand
end

-- Returns brand image name 
-- to use a portrait, pass (portrait, true)
-- to use a brand image, pass (brandImage, _, true)
-- to get from scratch, pass (playerId)
function prt.getBrandType(pid, boo, boo2)
	local brand = ""
	
	if boo2 then brand = pid else
	brand = prt.extractBrand(pid, boo) end
	
	return string.sub(brand, 25, 25)
end

-- to get tones from scratch, pass (playerId)
-- to use a portrait, pass (portrait, true)
-- to use an image, pass (image, true, true)
function prt.extractDirectives(pid, boo, boo2)
    local directives = ""
    local bodyColors = {}
	local image = ""
	
	if boo2 then image = pid else
	image = prt.extractImage(pid, "body.png", boo) end	
	
	local dir_loc = string.find(image, "replace")
	directives = string.sub(image, dir_loc)

    return directives
end

-- returns an array of 4 hex strings of length 6
-- to get tones from scratch, pass (playerId)
-- to use a portrait, pass (portrait, true)
-- to use an image, pass (image, true, true) 
-- to use directives, pass (directives, true, true, true)
function prt.extractTones(pid, boo, boo2, boo3)
	local bodyColors = {}
	local directives = ""
	
	if boo3 then directives = pid else
	directives = prt.extractDirectives(pid, boo, boo2) end
	
	--bodyColor1 = string.sub(directives, 16 ,21 )
    --bodyColor2 = string.sub(directives, 30 ,35 )
    --bodyColor3 = string.sub(directives, 44 ,49 )
    --bodyColor4 = string.sub(directives, 58 ,63 )
    --sb.logInfo("%s, %s, %s, %s", bodyColor1, bodyColor2, bodyColor3, bodyColor4)
	
	for i = 1, 4 do
		-- TODO: this was written a while ago, I should check the directives string again to ensure this will always work
		bodyColors[i] = string.sub(directives, (16 + (14 * (i - 1))), 21 + (14 * (i - 1)))
		--table.insert(bodyColors, i, string.sub(directives, (16 + (14 * (i - 1))), 21 + (14 * (i - 1))))
	end
	
	--for k, v in ipairs(bodyColors) do sb.logInfo("%s, %s", k, v) end
	return bodyColors
end
