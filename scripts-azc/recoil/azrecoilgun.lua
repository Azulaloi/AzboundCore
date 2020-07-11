require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/ranged/azweapon.lua"

function init()
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
end

function update(dt, fireMode, shiftHeld, moves)
    self.weapon:update(dt, fireMode, shiftHeld, moves)

    --local id = self.recoilId
    --self.weapon:receiveCam(id)
end

function uninit()


    self.weapon:uninit()
end

