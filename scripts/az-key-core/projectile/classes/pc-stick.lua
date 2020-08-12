require "/scripts/vec2.lua"
require "/scripts/util.lua"

pstick = {}
addClass("pstick", projectile.getParameter("pc-stick_priority", 100))

-- Projectile Class: Stick
-- Handles sticking behavior
-- I might want to separate the sticking behavior and detonation behavior into separate classes, TBD
-- TODO: expose values via functions

-- Remember, careful with globals

function pstick:init()
	-- TODO: maybe load parameters as a table? could be better for organizing if, in the projectile,
	-- each class has its own table of parameters that overwrite internal defaults. will think about it
	
	-- okay I thought about and made some other config loaders but I'm not sure any of them are actually better
	-- they're interesting but lets stick (heehee) with type0 for now

	pstick:initType0()
	
	if self.stickToStatic then mcontroller.applyParameters({stickyCollision = self.stickToStatic}) end
	
	self.queryRange = 1
	self.stuckEntity = nil
	self.stuck = false
	self.stuckStatic = false
	
	self.relativePos = {0, 0}
	
	self.toldToDie = false
	pstick:initHandlers()
	
	util.setDebug(true)
end

-- this is the normal method of loading parameters
function pstick:initType0()
	local function gcf(str, def) return projectile.getParameter("pc-stick_" .. str, def) end

	-- stickToStatic: apply stickyCollision? overrides physics type parameters
	self.stickToStatic = gcf("stickToStatic", false)
	-- stickEntWhenSS: stick to entity if stuck to geometry? only applies if stickToStatic is enabled
	self.stickEntWhenStatic = gcf("stickEntityWhenStuckStatic", false)
	-- stickStaWhenSE: stick to geometry if stuck to entity? 
	self.stickStaWhenEntity = gcf("stickStaticWhenStuckEntity", false)
end

-- like Type0, but loads from a table
function pstick:initType1()
	self.cfgParam = projectile.getParameter("pc-stick_config")
	
	self.stickToStatic = cpc("stickToStatic", false)
	self.stickEntWhenStatic = cpc("stickEntityWhenStuckStatic", false)
	self.stickStaWhenEntity = cpc("stickStaticWhenStuckEntity", false)
	
	local function cpc(str, def) 
		local p = self.cfgParam[str]
		return (p ~= nil) and p or def
	end
end

-- this one has a table of defaults, then loads params over it
-- very bad, it should be 1 line max per parameter
function pstick:initType2()
	self.cfg = {
		stickToStatic = false,
		stickEntWhenStatic = false,
		stickStaWhenEntity = false
	}

	self.cfgParam = projectile.getParameter("pc-stick_config")
	
	foo("stickToStatic", "stickToStatic")
	foo("stickEntWhenStatic", "stickEntityWhenStuckStatic")
	foo("stickStaWhenEntity", "stickStaticWhenStuckEntity")
	
	local function foo(a, str, def)
		local p = self.cfgParam[str]
		
		-- to set values as they are now
		self[a] = (p ~= nil) and p or self.cfg[a]

		-- to set values to self.cfg (two below lines are equivalent)
		--self.cfg[a] = (p ~= nil) and p or self.cfg[a]
		--if (p ~= nil) then self.cfg[a] = p end
	end
end

-- like 2, but 1 line per parameter could modify to load to self instead of .cfg
-- basically type1 except it loads to a table?
function pstick:initType3()
	self.cfgParam = projectile.getParameter("pc-stick_config")
	
	-- The idea is that I can place the internal name, default, and external (verbose) name in one line
	-- then load them all to a table
	self.cfg = fum({
		{ "stickToStatic", false, "stickToStatic" },
		{ "stickEntWhenStatic", false, "stickEntityWhenStuckStatic" },
		{ "stickStaWhenEntity", false, "stickStaticWhenStuckEntity" }
	})
	
	local function fum(tab)
		local out = {}
		
		for i, v in ipairs(tab) do
			local p = self.cfgParam[v[3]]
			out[v[1]] = (p ~= nil) and p or v[2] 
		end
		
		return out
	end
end


function pstick:initHandlers()
	message.setHandler("detonate", function(_, _)
		self.toldToDie = true
		pstick:detonate()
	end)
	
	message.setHandler("check", function(_, _, timeIn)
		if timeIn then projectile.setTimeToLive(timeIn) end
		--return "yo what up nerd, it me, projectile"
	end)
	
	-- TODO: handler for remote de-sticking? idk
end

function pstick:update(dt)
	-- Attempt to stick
	if not self.stuck then pstick:attemptStick() end

	-- Check stuck target extancy
	local entExtant = false
	if self.stuckEntity and world.entityExists(self.stuckEntity) then entExtant = true end
	
	-- Stuck behavior
	if self.stuck then
		if entExtant then
			pstick:doStuck()
		else
			pstick:stick(false)
		end
	end
	
	pstick:drawDebug(entExtant)
end

function pstick:attemptStick()
	local target = nil
	
	-- Are we stuck in geometry
	if self.stickToStatic then
		self.stuckStatic = mcontroller.isCollisionStuck()
	end
	
	-- Depending on stickStatic settings, search for a stick target
	if (not self.stuckStatic) or (self.stuckStatic and self.stickEntWhenStatic) then
		target = pstick:findTarget()
		if target then pstick:stick(target) end
	end
end

function pstick:doStuck()
	mcontroller.setVelocity({0,0})
	local targetVel = world.entityVelocity(self.stuckEntity)
	sb.logInfo("StuckTargetVel: " .. "x " .. tostring(targetVel[1]) .. " y " .. tostring(targetVel[2]))
	sb.logInfo("g: " .. tostring(world.gravity(mcontroller.position())))
	
	--grounded entities have a negative velocity that keeps them grounded, causing the grenade to fall
	projectile.setReferenceVelocity(targetVel)
	
	--does not account for mass, so lift will be greater than downforce
	--mcontroller.setYVelocity(world.gravity(mcontroller.position()) * 0.025)
	
	local rpws = vec2.add(world.entityPosition(self.stuckEntity), self.relativePos)
	local toTarget = world.distance(rpws, mcontroller.position())
	--toTarget = vec2.norm(toTarget)
	
	local speed = 40
	local control = 100
	mcontroller.approachVelocity(vec2.mul(toTarget, speed), control)
	
	
	--mcontroller.setPosition(vec2.add(world.entityPosition(self.stuckEntity), self.relativePos))
end

function pstick:drawDebug(entExtant)
	local colour = "white"
	if self.stuck then colour = "red" else colour = "white" end
	util.debugCircle(mcontroller.position(), self.queryRange, colour, 5)
	
	if entExtant then 
		world.debugLine(mcontroller.position(), world.entityPosition(self.stuckEntity), "blue")
	end
	
	if entExtant and self.stuck then
		if self.relativePos then
			local stickPos = vec2.add(world.entityPosition(self.stuckEntity), self.relativePos)
			world.debugLine(mcontroller.position(), stickPos, "red")
			world.debugPoint(stickPos, "blue")
		end
	end
	
	world.debugText(tostring(projectile.timeToLive()), vec2.add(mcontroller.position(), {1, 1}), "green")
end

function pstick:stick(entityId)
	if entityId then
		self.stuck = true
		self.stuckEntity = entityId
		mcontroller.setVelocity({0,0})
		mcontroller.applyParameters({gravityEnabled = false, collisionEnabled = false})
		if (not self.stickStaWhenEntity) then mcontroller.applyParameters({stickyCollision = false}) end
		
		self.relativePos = vec2.sub(world.entityPosition(entityId), mcontroller.position())
		-- gotta flip it 
		self.relativePos[1] = -self.relativePos[1]
		self.relativePos[2] = -self.relativePos[2]
		
		--todo: grab the proj rotation at stick, and maintain it relative to rotation of entity
		
		-- get the mass for countering downforce
		local maybeMonsterType = world.monsterType(entityId)
		if maybeMonsterType then sb.logInfo("stuck entity mass: " .. tostring(root.monsterMovementSettings(maybeMonsterType).mass)) end
		
		--projectile.setTimeToLive(4)
	else 
		self.stuck = false
		self.stuckEntity = nil
		mcontroller.applyParameters({gravityEnabled = true, collisionEnabled = true})
		if (not self.stickStaWhenEntity) then mcontroller.applyParameters({stickyCollision = self.stickToStatic}) end
	end
end

function pstick:findTarget()
	local nearEntities = {}
	
	if not self.stuckEntity then
		nearEntities = world.entityQuery(mcontroller.position(), self.queryRange, {
		includedTypes = {"npc", "monster", "player"},
		order = "nearest" })
	end
	
	nearEntities = util.filter(nearEntities, function(entityId)
		if not world.entityCanDamage(projectile.sourceEntity(), entityId) then
			return false
		end
		
		if world.entityDamageTeam(entityId).type == "passive" then
			return false
		end
	
		return true
	end)
	
	if #nearEntities > 0 then
		return nearEntities[1]
	else return false end
end

function pstick:detonate()
	projectile.die()
end

function pstick:destroy()
	if (not self.toldToDie) and projectile.sourceEntity() then
		world.sendEntityMessage(projectile.sourceEntity(), "projectileDestroyed", entity.id())
	end
end

----
-- getters
----

-- should this be getIsStuck or just isStuck?
function pstick:getIsStuck()
	return self.stuck
end

-- should this return false or nil? 
-- should this check extancy?
function pstick:getStuckEntity()
	return (self.stuck) and self.stuckEntity or false
end