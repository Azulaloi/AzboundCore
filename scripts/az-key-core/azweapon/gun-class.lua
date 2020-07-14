require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/az-key-core/azweapon/weapon.lua"

gunLoad = { 
	--weapon = {},
	testval = 5 
}
classes = {}

function init()
	--sb.logInfo("gun-class mt " .. tostring(getmetatable))

    activeItem.setCursor("/cursors/reticle0.cursor")
    animator.setGlobalTag("paletteSwaps", config.getParameter("paletteSwaps", ""))

    self.weapon = Weapon:new()

    self.weapon:addTransformationGroup("weapon", {0,0}, 0)
    self.weapon:addTransformationGroup("muzzle", self.weapon.muzzleOffset, 0)

    local primaryAbility = getPrimaryAbility()
    self.weapon:addAbility(primaryAbility)

    local secondaryAbility = getAltAbility(self.weapon.elementalType)
    if secondaryAbility then
        self.weapon:addAbility(secondaryAbility)
    end
	
    self.weapon:init()
	
	-- this is probably dumb but it works for now
	setmetatable(gunLoad, extend(self))
	
	for i, v in ipairs(config.getParameter("classes")) do
		require(v)
	end
	
	for i, v in ipairs(condense(classes, false)) do
		if _ENV[v] and _ENV[v].init then 
			_ENV[v]:init()
		end
	end
	
	--gunLoad.weapon = self.weapon
end

function update(dt, fireMode, shiftHeld, moves)
    self.weapon:update(dt, fireMode, shiftHeld, moves)

    self.weapon:updateScale()
	
	for i, v in ipairs(condense(classes, false)) do
		if _ENV[v] and _ENV[v].update then 
			_ENV[v]:update(dt, fireMode, shiftHeld, moves)
		end
	end
end

function uninit()
    self.weapon:uninit()
	
	for i, v in ipairs(condense(classes)) do
		if _ENV[v] and _ENV[v].uninit then
			_ENV[v]:uninit()
		end
	end
end

function condense(tabIn)
	local tabOut = {}
	assert(type(tabIn) == "table", "table no good")
	
	for k, v in pairs(tabIn) do
		if type(k) == "number" then tabOut[#tabOut+1] = tabIn[k] end
	end
	
	return tabOut
end

function addClass(name, order)
	if order then
		classes[50 + order] = name return
	else table.insert(classes, name) end
end

