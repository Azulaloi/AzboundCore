require "/scripts/util.lua"
require "/scripts/interp.lua"

-- Base gun fire ability
GunFire = WeaponAbility:new()

function GunFire:init()
  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = self.fireTime

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
  
  storage.activeProjectiles = storage.activeProjectiles or {}
  
  self.fireHeld = false
  self.checkTimer = 3
  self.hasCheckedOnce = false
  
  -- since the only two remote weapons are both single shot, the ammo tracker will just be a bool
  self.loaded = true
  
  self:initHandlers()
end

function GunFire:initHandlers()
	message.setHandler("projectileKilled", function(_, _, projId)
		self:projectileKilled(projId)
	end)
end

function GunFire:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
  self.checkTimer = math.max(0, self.checkTimer - self.dt)
  
  if animator.animationState("firing") ~= "fire" then
    animator.setLightActive("muzzleFlash", false)
  end
  
  if not self.hasCheckedOnce then self:updateProjectiles() end
  
  if self.shouldUpdateProjectiles and (self.checkTimer == 0) then
	self:updateProjectiles()
  end

  local flagFire = fireMode == (self.activatingFireMode or self.abilitySlot)
  local flagLoaded = true
  if self.useAmmo then flagLoaded = self.loaded end
  
  if flagFire
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy")
    and not world.lineTileCollision(mcontroller.position(), self:firePosition()) 
	then
	
	--sb.logInfo("az-gfr: fire1")
	if shiftHeld and self.useAmmo then
		self:setState(self.reload)
	elseif flagLoaded then
		if (self.fireType == "semi") and not self.fireHeld then
		  self:setState(self.fire)
		elseif self.fireType == "auto" and status.overConsumeResource("energy", self:energyPerShot()) then
		  self:setState(self.auto)
		elseif self.fireType == "burst" then
		  self:setState(self.burst)
		elseif self.fireType == "charge" then
		  self:setState(self.charge)
		end
	else
		if (self.fireType ~= "semi") then
		  self:setState(self.click)
		elseif (self.fireType ~= "semi") and not self.fireHeld then 
		  self:setState(self.click)
		end
	end -- these mixed tabs are so gross
  end -- blame notepad++ not me
  
  --if flagFire then
	self.fireHeld = flagFire
  --end
  
  if (self.detType == "hold") and not self.fireHeld then
	if #storage.activeProjectiles > 0 then
		self:triggerProjectiles()
	end
  end
  
  self:drawDebug(flagFire, flagLoaded)
end

function GunFire:drawDebug(flagFire, flagLoaded)
		local pos = mcontroller.position()
		world.debugText("Projectiles: ", vec2.add(pos, {8, 2}), "green")
		for i = 1, #storage.activeProjectiles do
			local pY = 2 - (0.5 * i)
			world.debugText("[" .. tostring(i) .. "]", vec2.add(pos, {8, pY}), "green")
			world.debugText(tostring(storage.activeProjectiles[i]), vec2.add(pos, {9, pY}), "green")
		end
		
		local str0 = self.fireHeld and "true" or "false"
		world.debugText("fireHeld: " .. str0, vec2.add(pos, {4, 2}), "green")
		
		local str1 = flagFire and "true" or "false"
		world.debugText("flagFire: " .. str1, vec2.add(pos, {4, 1.5}), "green")
		
		local str2 = flagLoaded and "true" or "false"
		world.debugText("flagLoaded: " .. str2, vec2.add(pos, {4, 1}), "green")
end

-- STATES --

function GunFire:auto()
  self.weapon:setStance(self.stances.fire)

  self:fireProjectile()
  self:muzzleFlash()

  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration)
  end

  self.cooldownTimer = self.fireTime
  self:setState(self.cooldown)
end

function GunFire:burst()
  self.weapon:setStance(self.stances.fire)

  local shots = self.burstCount
  while shots > 0 and status.overConsumeResource("energy", self:energyPerShot()) do
    self:fireProjectile()
    self:muzzleFlash()
    shots = shots - 1

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.armRotation))

    util.wait(self.burstTime)
  end

  self.cooldownTimer = (self.fireTime - self.burstTime) * self.burstCount
end

function GunFire:charge()
  self.weapon:setStance(self.stances.charge)
  
  local chargeTimer = self.stances.charge.duration
  
  while chargeTimer > 0 and self.fireMode == (self.activatingFireMode or self.abilitySlot) do
	chargeTimer = chargeTimer - self.dt
	
	world.debugText(sb.print("Charge: " .. chargeTimer), vec2.add(mcontroller.position(), {1, 2}), "green")
	
	coroutine.yield()
  end
  
  if chargeTimer <= 0 then
	self:setState(self.fire)
  else 
	self:setState(self.cooldown)
  end
 
end

function GunFire:fire()
  self.weapon:setStance(self.stances.fire)
  
  local proj = self:fireProjectile()
  self:muzzleFlash()
  
  if proj then self:doLoad(false) end
  
  if self.stances.fire.duration then
	util.wait(self.stances.fire.duration)
  end
  
  self.cooldownTimer = self.fireTime
  self:setState(self.cooldown)
end

function GunFire:click()
	self.weapon:setStance(self.stances.fire)

	self:playSoundSafe("click")
	
	if self.stances.fire.duration then
        util.wait(self.stances.fire.duration)
    end
	
	self.cooldownTimer = self.fireTime
    self:setState(self.cooldown)
end

function GunFire:reload()
	self.weapon:setStance(self.stances.fire)

	self:playSoundSafe("reload")
	
	if self.stances.fire.duration then
        util.wait(self.stances.fire.duration)
    end
	
	self:doLoad(true)
	
	self.cooldownTimer = self.fireTime
    self:setState(self.cooldown)
end

-- AMMO --

function GunFire:doLoad(loadIn)
	if loadIn then
		self.loaded = true
		animator.setAnimationState("loaded", "true")
	else 
		self.loaded = false
		animator.setAnimationState("loaded", "false")
	end
end

function GunFire:cooldown()
  self.weapon:setStance(self.stances.cooldown)
  self.weapon:updateAim()

  local progress = 0
  util.wait(self.stances.cooldown.duration, function()
    local from = self.stances.cooldown.weaponOffset or {0,0}
    local to = self.stances.idle.weaponOffset or {0,0}
    self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.cooldown.weaponRotation, self.stances.idle.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.cooldown.armRotation, self.stances.idle.armRotation))

    progress = math.min(1.0, progress + (self.dt / self.stances.cooldown.duration))
  end)
end

-- OTHER FUNCTIONS --

function GunFire:muzzleFlash()
  animator.setPartTag("muzzleFlash", "variant", math.random(1, 3))
  animator.setAnimationState("firing", "fire")
  animator.burstParticleEmitter("muzzleFlash")
  animator.playSound("fire")

  animator.setLightActive("muzzleFlash", true)
end

function GunFire:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)
  local params = sb.jsonMerge(self.projectileParameters, projectileParams or {})
  params.power = self:damagePerShot()
  params.powerMultiplier = activeItem.ownerPowerMultiplier()
  params.speed = util.randomInRange(params.speed)

  if not projectileType then
    projectileType = self.projectileType
  end
  if type(projectileType) == "table" then
    projectileType = projectileType[math.random(#projectileType)]
  end

  local projectileId = false
  for i = 1, (projectileCount or self.projectileCount) do
    if params.timeToLive then
      params.timeToLive = util.randomInRange(params.timeToLive)
    end

    projectileId = world.spawnProjectile(
        projectileType,
        firePosition or self:firePosition(),
        activeItem.ownerEntityId(),
        self:aimVector(inaccuracy or self.inaccuracy),
        false,
        params
      )
  end
  
  if projectileId then table.insert(storage.activeProjectiles, projectileId) end
  
  if self.weapon.recoilToggle then
      self.weapon:recoil({
          (math.random(self.recoilXAlpha) - self.recoilXBeta) / self.recoilXDividend,
          (math.random(self.recoilYAlpha) - self.recoilYBeta) / self.recoilYDividend})
  end
	
  return projectileId
end

function GunFire:firePosition()
	--return activeItem.ownerAimPosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function GunFire:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function GunFire:energyPerShot()
  return self.energyUsage * self.fireTime * (self.energyUsageMultiplier or 1.0)
end

function GunFire:damagePerShot()
  return (self.baseDamage or (self.baseDps * self.fireTime)) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier") / self.projectileCount
end

function GunFire:uninit()
    --local id = self.recoilId
    --if id then
    --  if world.entityExists(id) then
    --    world.sendEntityMessage(id, "return")
    --  end
    --end
end

-- PROJECTILE MANAGEMENT --

function GunFire:updateProjectiles()
	-- I know table.remove is slow but there probably won't be more than like a dozen entries max

	local toRemove = {}
	for i, v in ipairs(storage.activeProjectiles) do
		if world.entityExists(v) then 
			if self.shouldCheckMessage then
				local msg = world.sendEntityMessage(v, self.shouldCheckMessage, self.shouldCheckTTL or 6)
			end
		else 
			--table.insert(toRemove, i) 
			toRemove[v] = true
		end
	end
	
	local iter = 1
	while iter <= #storage.activeProjectiles do
		if toRemove[storage.activeProjectiles[iter]] then
			table.remove(storage.activeProjectiles, iter)
		else
			iter = iter + 1
		end
	end
	
	self.checkTimer = self.checkTime or 5
end

function GunFire:triggerProjectiles()
	sb.logInfo("az-gfr: triggering " .. tostring(#storage.activeProjectiles) .. " projectiles")
	self:playSoundSafe("trigger")
	for i, v in ipairs(storage.activeProjectiles) do
		world.sendEntityMessage(v, self.detFunction)
	end
end

function GunFire:projectileKilled(projId)
	for i, v in pairs(storage.activeProjectiles) do
		if v == projId then
			table.remove(storage.activeProjectiles[i])
			break
		end
	end
end

-- UTIL --

function GunFire:playSoundSafe(sound, loopsIn)
	local loops = loopsIn or 0
	if animator.hasSound(sound) then
		animator.playSound(sound, loops)
	else 
		sb.logWarn("azc-gunfireremote: Item <" .. tostring(item.name)
		.. "> tried to play undefined sound <" .. sound .. ">") 
	end
end