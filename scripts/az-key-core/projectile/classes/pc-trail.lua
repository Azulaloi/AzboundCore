require "/scripts/vec2.lua"
require "/scripts/util.lua"

ptrail = {}
addClass("ptrail", projectile.getParameter("pc-trail_priority", 100))

-- Projectile Class: Trail
-- Creates a trail of streak particles. 
-- Based on trailprojectile.lua that I made for EAH

-- Should have feature parity with trailprojectile.lua
-- By should, I mean: Az, you better keep them equivalent, you slag

function ptrail:init()
	self.lastPos = mcontroller.position()
	self.lastVel = mcontroller.velocity()
	
	local function gcf(str, def) return config.getParameter("pc-trail_" .. str, def) end
	
	self.delta = gcf("trailDelta", 1)
	self.trailQuantity = tonumber(gcf("trailQuantity", 1))
	self.delayTimer = gcf("trailDelay", 2)
	self.offset = gcf("trailOffset", 0)
	self.bridge = gcf("trailBridge", true)
	
	self.trailConfigs = {}
	for i = 1, self.trailQuantity do
		table.insert(self.trailConfigs, (gcf("trailConfig" .. i)))
	end
	
	ptrail:initDefaults()
	
	-- this is (approximately) the ratio of a velocities distance in a tick to the appropriate trail length
	self.mnum = 0.1339 * self.delta
	
	-- Disabled but left until I add a delta handler to the class loader
	--script.setUpdateDelta(self.delta)
	
	--azLog("ptrail init")
end

function ptrail:initDefaults()
	self.default = {}
	self.default.thiccness = 1
	self.default.lifeTime = 0.4
	self.default.destTime = 0.4
	self.default.destAction = "shrink"
	self.default.fullbright = false
	self.default.layer = "back"
	self.default.color = {190, 190, 190, 200}
	
	self.default.thiccVar = 0
	self.default.colorVar = {0, 0, 0, 0}
end

function ptrail:update(dt)
	self.delayTimer = self.delayTimer - 1
	
	if self.delayTimer < 1 then
		local pos = mcontroller.position()
		local vel = mcontroller.velocity()
	
		local lv = self.mnum * vec2.mag(vel)
		
		local steps = 8
		local trail = false
		
		if (steps > 0) then
			-- Linear interpolation
			local mlv = lv / (steps + 1)
			trail = ptrail:spawnTrails(pos, vel, mlv, false, true)
			
			local points = ptrail:lerpPoints(self.lastPos, pos, steps)
			for i = 1, steps do
				if points[i] then
					ptrail:spawnTrails(points[i], vel, mlv, false, true, true)
				end
			end
		else
			-- No interpolation
			trail = ptrail:spawnTrails(pos, vel, lv, false, true)
		end
		
		if trail then 
			self.lastPos = pos
			self.lastVel = vel
		end
	end
end

-- Corrects for the gap between last trail and destruction position
function ptrail:destroy()
	if self.lastPos and self.bridge then	
		local destPos = mcontroller.position()
	
		-- 1 streak length unit is 1/8th of a world unit (I think, I'm a little tired) 
		local scalar = 8
		
		-- this is the distance between the last trail particle and the destruction pos
		local lengthCalc = vec2.mag(vec2.sub(self.lastPos, destPos))
		local posCalc = alongAngle(self.lastPos, self.lastVel, lengthCalc)
		
		local spawnPos = posCalc
		
		--spawnDebug(spawnPos, self.lastPos, destPos, self.lastVel, posCalc)
		ptrail:spawnTrails(spawnPos, self.lastVel, lengthCalc * scalar, true, true)
	end
end

function ptrail:spawnTrails(posIn, velIn, lengthIn, destBool, velBool, interpBool)
	local trail = nil
	for i = 1, self.trailQuantity do
		trail = ptrail:spawnTrail(posIn, velIn, lengthIn, destBool, velBool, i, (interpBool or false))
	end
	
	-- this could be made to return a table of projectiles, rather than the most recently created,
	-- but since this is being called potentially every tick, it's probably best to use as little memory as possible.
	return trail
end

function ptrail:spawnTrail(posIn, velIn, lengthIn, destBool, velBool, iter, interpBool)
	local param = self.trailConfigs[iter]

	useVel = velBool or true
	local v = {0, 0}
	
	if useVel and not destBool then 		
		v = ptrail:alongAngle({0, 0}, mcontroller.velocity(), self.offset)
	end

	local projPos = posIn
	if destBool then
		-- for some reason, spawning the projectile near a slope would displace it.
		-- no idea why, possibly some obscure internal workaround, whatever.
		-- solution: instead of spawning the projectile at the destPos or posCalc, we just
		-- spawn the proj at lastPos and offset the particle position. 
	
		projPos = self.lastPos
		v = vec2.sub(self.lastPos, posIn)
		v = ptrail:alongAngle(v, velIn, (lengthIn / 8) * 2)
	end
	
	-- Temporary interp highlight color
	local prepColor = (interpBool and {255, 0, 0, 200}) or (param.color or self.default.color)

	return world.spawnProjectile("azdebug", projPos, 0, {0, 0}, false, {
	timeToLive = 0.0,
	actionOnReap = {
	{
		action = "particle",
		specification = {
		  type = "streak",
          layer = param.layer 	or 					self.default.layer,
          fullbright = param.fullbright or 			self.default.fullbright,
          destructionAction = param.destAction or 	self.default.destAction,
          size = param.thiccness or 				self.default.thiccness,
          color = prepColor,
          collidesForeground = false,
          length = lengthIn,
          position = v,
          timeToLive = param.lifeTime or 			self.default.lifeTime,
          destructionTime = param.destTime or 		self.default.destTime,
          initialVelocity = vec2.mul(vec2.norm(velIn), 0.1),
		  --fade = 1,
          variance = {
            size = param.thiccVar or 				self.default.thiccVar,
			color = param.colorVar or 				self.default.colorVar,
            --destructionTime = 0.55,
		    initialVelocity = {0, 0},
            length = 0
          }
		}
	  }
	}
	})
end

function ptrail:spawnDebug(posIn, lastPosIn, destPosIn, lastVelIn, posCalcIn)
	return world.spawnProjectile("aztraildebug", posIn, 0, {0, 0}, false, {
	timeToLive = 5.0,
	lastPos = lastPosIn,
	destPos = destPosIn,
	lastVel = lastVelIn,
	posCalc = posCalcIn
	})
end

function ptrail:alongAngle(pos, angle, dist)
	local u = vec2.norm(angle)
	local du = vec2.mul(u, dist)
	return vec2.add(pos, du)
end

function ptrail:lerpPoints(pA, pB, steps)
	local delta = {pA[1] - pB[1], pA[2] - pB[2]}
	delta = ptrail:vecFlip(delta)
	
	local inter = {delta[1] / (steps + 1), delta[2] / (steps + 1)}
	
	local points = {}
	for i = 1, steps do
		local m = vec2.mul(inter, i)
		--p = {pA[1] + (inter[1] * i), pA[2] + (inter[2] * i)}
		p = {pA[1] + m[1], pA[2] + m[2]}
		table.insert(points, p)
	end
	
	return points
end

function ptrail:vecFlip(vec)
	return {-vec[1], -vec[2]}
end