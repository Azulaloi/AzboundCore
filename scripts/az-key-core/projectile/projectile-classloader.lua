require "/scripts/util.lua"
require "/scripts/vec2.lua"

loader = {}
classes = {}
 
-- TODO: allow configuring priority of classes in item config rather than in the class script
-- TODO: allow configuring delta of classes 
-- should the delta be configured from the script, or in the item config? if it's from the script, it could also get it from config... hmm....

function init()
	self.verbosity = 100

	for i, v in ipairs(config.getParameter("classes")) do
		sb.logInfo("pc #" .. tostring(i) .. ": " .. tostring(v))
		require(v)
	end
	
	for i, v in ipairs(condense(classes, false)) do
		if _ENV[v] and _ENV[v].init then 
			_ENV[v]:init()
		end
	end
	
	--self.classes = condense(classes) or {}
end

function update(dt)
	for i, v in ipairs(condense(classes)) do
		if _ENV[v] and _ENV[v].update then 
			_ENV[v]:update(dt)
		end
	end
end

function uninit()
	for i, v in ipairs(condense(classes)) do
		if _ENV[v] and _ENV[v].uninit then
			_ENV[v]:uninit()
		end
	end
end

function bounce()
	for i, v in ipairs(condense(classes)) do
		if _ENV[v] and _ENV[v].bounce then
			_ENV[v]:bounce()
		end
	end
end

function destroy()
	for i, v in ipairs(condense(classes)) do
		if _ENV[v] and _ENV[v].destroy then
			_ENV[v]:destroy()
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

-- TODO: override internal priority from projectile config
function addClass(name, order)
	if order then
		classes[50 + order] = name return
	else table.insert(classes, name) end
end

-----
-- COMMON FUNCTIONS
-----

function azLog(str, priorityIn, levelIn, prefixIn)
	-- TODO: get the name of the context it was called from somehow (at least the projectile name)

	local priority = priorityIn and priorityIn or 1
	local level = levelIn or 0
	local prefix = prefixIn and prefixIn or "az-pcl: "
	if self.verbosity >= priority then
		if level < 1 then
			sb.logInfo(prefix .. str)
		elseif level < 2 then
			sb.logWarn(prefix .. str)
		elseif level < 3 then
			sb.logError(prefix .. str)
		end
	end
end