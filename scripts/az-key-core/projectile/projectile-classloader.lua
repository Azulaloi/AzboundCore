require "/scripts/util.lua"
require "/scripts/vec2.lua"

loader = {}
classes = {}

function init()
	for i, v in ipairs(config.getParameter("classes")) do
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

function addClass(name, order)
	if order then
		classes[50 + order] = name return
	else table.insert(classes, name) end
end