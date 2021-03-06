require "/scripts/util.lua"
require "/scripts/interp.lua"

-- AzCore GunFire (key)
-- I don't even wanna hear it about the mixed tabs. Blame notepad++. 

GunFire = WeaponAbility:new()

function GunFire:init()
  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = self.fireTime

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
 
  -- class loader test
  --if gunLoad ~= nil then
  --  sb.logInfo(tostring(gunLoad.testval))
  --end
  
  self:initParameters()
end

function GunFire:initParameters()
  -- abilities automatically add all configured parameters to self table
  -- so we must set defaults for manually
  
  -- the pattern: '((param ~= nil) and param) or default' sets param to default if nil. 
  -- nil evaluates to false as boolean so extra verbage is necessary when setting boolean with pseudo-ternary
  self.triggerMode = self.triggerMode or "auto"
  self.actionMode = self.actionMode or "single"
  self.burstTerm = ((self.burstTerm ~= nil) and self.burstTerm) or true  
  self.burstCount = self.burstCount or 3
  self.burstTime = self.burstTime or 0.1
  
  self.chargeMode = ((self.chargeMode ~= nil) and self.chargeMode) or false 
  self.chargeHold = ((self.chargeHold ~= nil) and self.chargeHold) or true
  self.chargeStore = self.chargeStore or 0
  self.chargeDecay = self.chargeDecay or 1
  self.chargeMax = self.chargeMax or 2
  self.chargeTimer = self.chargeMax
  
  self.inaccuracy = self.inaccuracy or 0
  self.blooming = ((self.blooming ~= nil) and self.blooming) or false
  self.bloomBase = self.instability or 0.005
  self.bloomFac = self.bloomFac or 1
  self.bloomDecay = self.bloomDecay or 3
  self.bloomDelay = self.bloomDelay or 0
  self.bloomMax = self.bloomMax or 0.5
  
  -- internal values
  self.fireHeld = false
  self.firedFor = false
  self.charging = false
  self.charged = false
  self.bloom = 0
  self.bloomTimer = 0 
end

----
-- TEMP DOCS (easier to reference here while working)
-- Config Parameters

-- self.triggerMode = "semi", "auto"
--   "semi" : trigger must be pressed for each actuation
--   "auto" : will continuously actuate while trigger is held

-- self.actionMode = "single", "burst"
--   "single" : each actuation will fire once
--   "burst"  : each actuation will fire for burstCount

-- self.burstTerm = boolean
--   true  : burst can be terminated by releasing trigger
--   false : burst will continue regardless of trigger state

-- self.chargeMode = boolean
--   toggles charge functionality

-- self.chargeStore = enum (ok fine its an int)
--   when charge state ends, 
--     0 : charge will reset
--     1 : charge will remain, but reset when action ends
--     2 : charge will remain even when action ends

-- self.chargeDecay = float
--   if chargeStore, charge will decay by (this * dt) while not charging
-----

--todo:
-- restore charge stance behavior
-- charge FX
-- charge burst functionality
-- burst should be able to optionally play a single effect on actuation instead of multiple shot effects
-- charge/non-charge hybrid behavior (like the vanilla dragonfire pistol)

function GunFire:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if animator.animationState("firing") ~= "fire" then
    animator.setLightActive("muzzleFlash", false)
  end
  
  local flagFire = fireMode == (self.activatingFireMode or self.abilitySlot)
  self.fireHeld = flagFire
  
  if flagFire
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy")
    and not world.lineTileCollision(mcontroller.position(), self:firePosition()) 
	then
	
	local flagSemi = (self.triggerMode == "semi" and not self.firedFor) or (self.triggerMode ~= "semi")
	
	if flagSemi and self.chargeMode then
		if self.charged then
			--if self.actionMode == "single" and status.overConsumeResource("energy", self:energyPerShot()) then
				--self:setState(self.fire) -- wait i guess im doing this logic in the state instead
			--end
			-- CHARGE BURST BEHAVIOR GOES HERE
		else
			self:setState(self.charge)
		end
	elseif flagSemi then
		if self.actionMode == "single" and status.overConsumeResource("energy", self:energyPerShot()) then
			self:setState(self.fire)
		elseif self.actionMode == "burst" then
			self:setState(self.burst)
		end
	end
  end
  
  if not self.fireHeld then
	self.firedFor = false
	
	if self.charged then -- CHARGE ACTION COMPLETED
		self.charged = false
		if (self.chargeStore < 2) then
			self.chargeTimer = self.chargeMax
		end
	end
	
	if self.charging then -- CHARGE ABORTED
		self.charging = false 
		if (self.chargeStore == 0) then
			self.chargeTimer = self.chargeMax
		end
	end
  end

  -- decay charge timer
  if (not (self.charging or self.charged)) and (self.chargeStore > 0) then
	self.chargeTimer = math.min(self.chargeTimer + (dt * self.chargeDecay), self.chargeMax)
  end
  
  if self.blooming then self:cycleBloom(dt) end
  
  self:drawDebug()
end

function GunFire:drawDebug()
	local pos = mcontroller.position()
	
	world.debugText("trigger:  " .. self.triggerMode, vec2.add(pos, {4, 2}), "green")
	world.debugText("action:   " .. self.actionMode, vec2.add(pos, {4, 1.5}), "green")
	world.debugText("cooldwn:  " .. round(self.cooldownTimer, 2), vec2.add(pos, {4, 1}), "green")
	
	if self.blooming then
		world.debugText("bloom:    " .. round(self.bloom, 2), vec2.add(pos, {4, 0.5}), "green")
		world.debugText("bTimer:   " .. round(self.bloomTimer, 2), vec2.add(pos, {4, 0}), "green")
	end
	
	local str0 = self.chargeMode and "true" or "false"
	local str00 = self.chargeMode and "" or (", " .. tostring(self.chargeStore))
	world.debugText("charge:  " .. str0 .. str00, vec2.add(pos, {8.5, 2}), "green")
	
	if self.chargeMode then
		local str1 = self.charging and "true" or "false"
		world.debugText("chrging: " .. str1, vec2.add(pos, {8.5, 1.5}), "green")
	
		world.debugText("chTimer: " .. round(self.chargeTimer, 2), vec2.add(pos, {8.5, 1}), "green")
	
		local str2 = self.charged and "true" or "false"
		world.debugText("charged: " .. str2, vec2.add(pos, {8.5, 0.5}), "green")
	end
end

----
-- FIRE STATES
----

function GunFire:fire()
  self.weapon:setStance(self.stances.fire)

  self:fireProjectile()
  self:muzzleFlash()
  
  self.firedFor = true
  if self.blooming then self:addBloom() end

  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration)
  end

  self.cooldownTimer = self.fireTime
  self:setState(self.cooldown)
end

function GunFire:burst()
  self.weapon:setStance(self.stances.fire)

  local termFlag = (self.burstTerm and self.fireHeld) or (not self.burstTerm)
  local shots = self.burstCount
  while shots > 0 and 
		status.overConsumeResource("energy", self:energyPerShot()) and
		termFlag do
	
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
  --self.weapon:setStance(self.stances.charge)
  self.weapon:setStance(self.stances.fire)
  
  playSoundSafe("charge")
  
  --local chargeTimer = self.stances.charge.duration
  if self.chargeStore <= 1 then
	self.chargeTimer = self.chargeMax
  end
  
  while self.chargeTimer > 0 and self.fireMode == (self.activatingFireMode or self.abilitySlot) do
    self.charging = true
	self.chargeTimer = self.chargeTimer - self.dt
	
	coroutine.yield()
  end
  
  animator.stopAllSounds("charge")
  
  if self.chargeTimer <= 0 then
	self.charging = false
	self.charged = true
	if self.chargeHold then self:setState(self.chargedState)
		else self:setState(self.fire) end
  else 
	self.charging = false
	self:setState(self.cooldown)
  end
end

function GunFire:chargedState()
	self.weapon:setStance(self.stances.fire)
	
	playSoundSafe("charged")
	playSoundSafe("chargedLoop", -1)
	
	while self.fireMode == (self.activatingFireMode or self.abilitySlot) do 
		
		mcontroller.controlModifiers({runningSuppressed = true})
	
		coroutine.yield()
	end
	
	animator.stopAllSounds("chargedLoop")
	self:setState(self.fire)
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

----
-- OTHER
----

function GunFire:addBloom(bIn)
	local toAdd = bIn or self.bloomBase
	self.bloom = math.min(self.bloom + (toAdd), self.bloomMax)
	--self.bloomTimer = -0.01
	--self.bloomTimer = -self.stances.cooldown.duration or -0.05
	self.bloomTimer = self.bloomDelay + (-self.stances.cooldown.duration) + (-self.fireTime)
end

function GunFire:cycleBloom(dt)
	self.bloomTimer = math.min(self.bloomTimer + dt, 2.5)
	--self.bloom = math.min(math.max(self.bloom - (dt * (self.bloomTimer * self.bloomDecay)), 0), self.bloomMax)
	local tmr = (self.bloomTimer > 0) and self.bloomTimer or 0 
	self.bloom = math.max(self.bloom - (dt * (tmr * self.bloomDecay)), 0), self.bloomMax
end

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

  local projectileId = 0
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
  
  if (self.ejectEnable) or (self.ejectType) then self:ejectCasing() end
  
  -- Recoil Cam
  if self.weapon.recoilToggle then
      self.weapon:recoil({
          (math.random(self.recoilXAlpha) - self.recoilXBeta) / self.recoilXDividend,
          (math.random(self.recoilYAlpha) - self.recoilYBeta) / self.recoilYDividend})
  end
	
  return projectileId
end


-- temp docs, im tired
-- todo: change the offset to not be based on muzzle pos!!!!

-- "ejectEnable" - force enables eject behavior with default projectile
-- "ejectType" - projectile type to eject (also enables eject behavior)
-- "ejectOffset" - vec2 offset from firePos to eject at
-- "ejectAngle" - angle in degrees to offset eject direction from aim angle by
-- "ejectFuzz - amount by which the angle can fuzz in either direction
-- "ejectSpeed" - speed (float or [min, max]) of ejected proj
-- "ejectCount" - number of projectiles to eject
function GunFire:ejectCasing(paramsIn, angleIn, angleFuzz, quantity)
  -- default doesn't exist yet so don't use it
  local projType = self.ejectType or "az-key_case-gen"
  
  local eParams = {}
  if paramsIn ~= nil then eParams = sb.jsonMerge({}, paramsIn) end
  
  -- Position
  local pPos = {0, 0}
  local pPosOffset = self.ejectOffset or {-0.5, 0}
  pPos = self:firePosition(pPosOffset)
  
  -- Rotation
  --local f = self.ejectFuzz or 5
  --local fuzz = util.randomInRange(-f, f) 
  local fuzz = sb.nrand(self.ejectFuzz or 5)
  local ang = self.ejectAngle and (self.ejectAngle + fuzz) or (180 + fuzz)
  local pVector = vec2.rotate({1, 0}, self.weapon.aimAngle + self:toRadians(ang))
  --local pVector = vec2.rotate({1, 0}, self.weapon.aimAngle)
  --pVector = vec2.rotate(pVector, self:toRadians(ang))
  pVector[1] = pVector[1] * mcontroller.facingDirection()
  --sb.logInfo("eject fuzz: " .. tostring(fuzz))
  --sb.logInfo("eject ang: " .. tostring(ang))
  
  -- Speed
  local s = self.ejectSpeed or {3, 6}
  local spd = util.randomInRange(s)
  eParams.speed = spd
  --sb.logInfo("eject speed: " .. tostring(spd))
  
  -- Spawn
  local projId = 0
  for i = 1, (quantity or self.ejectCount or 1) do
	
	projId = world.spawnProjectile(
	  projType,
	  pPos,
	  activeItem.ownerEntityId(),
	  pVector,
	  false,
	  eParams
	)
  end
  
  return projectileId
end

function GunFire:toRadians(degrees)
  return degrees * math.pi/180
end

function GunFire:firePosition(offsetIn)
  --local relativePos = vec2.add(self.weapon.muzzleOffset, (offsetIn or {0, 0}))

  -- it's probably cheaper to do a boolean check than vector arithmetic, right?
  -- or would it be better without branching?
  local relativePos = self.weapon.muzzleOffset
  if offsetIn then relativePos = vec2.add(relativePos, offsetIn) end
  
  return vec2.add(mcontroller.position(), activeItem.handPosition(relativePos))
end

function GunFire:aimVector(inaccuracy)
  local acc = self.blooming and (inaccuracy + (self.bloom * self.bloomFac)) or inaccuracy
  
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(acc, 0))
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

----
-- UTIL
----

function round(num, dec)
	return string.format("%." .. (dec or 0) .. "f", num)
end

function playSoundSafe(sound, loopsIn)
	local loops = loopsIn or 0
	if animator.hasSound(sound) then
		animator.playSound(sound, loops)
	else 
		sb.logWarn("azgunfire: Item <" .. tostring(item.name)
		.. "> tried to play undefined sound <" .. sound .. ">") 
	end
end
