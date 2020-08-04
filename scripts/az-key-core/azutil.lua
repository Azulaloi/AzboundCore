require "/scripts/util.lua"
require "/scripts/vec2.lua"

-- AzCore Util
-- This script contains varied useful utility functions. 
-- It may be required and used directly, taken from, or used as reference.
-- Note that some functions may call other azutil functions.

-- Warning: functions may require certain context(s). 

azutil = {}

----
-- VECTOR STUFF
--
-- legend:
-- int means a whole number, passing a float will cause unintended behavior
-- v2 is an array of two floats: {float, float}
-- ? in front of an arg means optional
-- 
-- most of these require vanilla vec2 lib "/scripts/vec2.lua"
----

-- alongAngle(v2, v2, float)
-- 	will return a position dist units from pos along the vector angle
function azutil:alongAngle(pos, angle, dist)
	local u = vec2.norm(angle)
	local du = vec2.mul(u, dist)
	return vec2.add(pos, du)
end

-- closestPointOnVector(v2, v2, v2)
-- 	will return the position along (ray at origin with angle angleVector) that is closest to point
function azutil:closestPointOnVector(origin, angleVector, point)
	local dir = vec2.norm(angleVector)
	local a = world.distance(point, origin)
	
	local dot = vec2.dot(a, dir)
	return vec2.add(origin, vec2.mul(dir, dot))
end

-- vecFlip(v2)
-- 	returns vec with values inverted
function azutil:vecFlip(vec)
	return {-vec[1], -vec[2]}
end

-- angleWithin(float, float, float)
-- 	returns true if angle is within thresh of anchor
function azutil:angleWithin(angle, anchor, thresh)
	return (angle >= (anchor - thresh) and angle <= (anchor + thresh))
end

-- MAINTENANCE ALERT: radians mode might not work right
-- 	angleDifference(float, float, bool)
-- 	returns the difference between two angles
function azutil:angleDifference(alpha, beta, radIn)
	local a = radBool and (alpha * 180/math.pi) or alpha
	local b = radBool and (beta * 180/math.pi) or beta

	local rawDiff = (a > b) and (a - b) or (b - a)
	local modDiff = rawDiff % 360
	
	--return 180 - math.abs(modDiff-180)
	return modDiff
end

-- shortestOrbit(float, float, bool)
-- 	returns the shortest difference in degrees to reach tarIn from curIn
-- 	set radIn to true if inputing radians
function azutil:shortestOrbit(curIn, tarIn, radIn)
	local radBool = radIn or false
	
	local cur = radBool and (curIn * 180/math.pi) or curIn
	local tar = radBool and (tarIn * 180/math.pi) or tarIn

	local a = tar - cur
	local b = tar - cur + 360
	local y = tar - cur - 360
	
	local tab = {a, b, y}
	
	local ind, val = 1, tab[1]
	for k, v in ipairs(tab) do
		if math.abs(tab[k]) < math.abs(val) then
			ind, val = k, v
		end
	end
	
	--sb.logInfo("motion: " .. tostring(tab[ind]))
	return tab[ind]
end

-- pointsCircle(int, float)
--   returns the positions of quant equidistant points on a circle of radius radius
--   as an array of v2 
function azutil:pointsCircle(quant, radius)
	local points = {}
	local theta = (2 * math.pi / quant)
	
	for i = 1, quant do
		local p = azutil:pointCircle(quant, radius, i, theta)
		points[i] = p
	end
	
	return points
end

-- pointCircle(float, float, int, float, ?float)
--   returns position (v2) of the iter-th of quant equidistant points on a circle of radius radius
--	 to clarify: quant is number of points, iter is which point to return the position of
--   thetaIn may optionally be passed in to save compute
function azutil:pointCircle(quant, radius, iter, thetaIn)
	--local theta = (2 * math.pi / quant) * iter
	--local theta = thetaIn and (thetaIn * iter) or ((2 * math.pi / quant) * iter) 
	local theta = thetaIn or (2 * math.pi / quant) 
	
	local pPos = { math.sin((theta * iter) + theta / 2), 
				   math.cos((theta * iter) + theta / 2) }
				   
	pPos = vec2.mul(pPos, radius)
	
	-- alternatively...
	--pPos = vec2.rotate({0, radius}, (2 * math.pi/quant) * iter)
	
	return pPos
end

-- lerpPoints(v2, v2, int)
--   returns steps equidistant points between pA and pB
--   as an array of v2
function azutil:lerpPoints(pA, pB, steps)
	--local delta = world.distance(pA, pB)
	local delta = {pA[1] - pB[1], pA[2] - pB[2]}
	delta = vecFlip(delta)
	
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

-- midPoint(v2, v2)
--   returns the midpoint of pA and pB as a v2
function azutil:midPoint(pA, pB)
	return {(pA[1] + pB[1]) / 2, (pA[2] + pB[2]) / 2}
end


-- circlePos(float, float)
--   returns the pos (v2) on a circle of radius radius at angle degrees
function azutil:circlePos(angle, radius)
	return vec2.rotate({radius, 0}, angle)
end

-- vecPrint(v2, int)
--   returns v2 as a readable string rounded to decIn decimal places
function azutil:vecPrint(vecIn, decIn)
	local dec = decIn or 3
	--return "x" .. tostring(vecIn[1]) .. " : " .. "y" .. tostring(vecIn[2]) 
	return "x" .. azutil:round(vecIn[1], dec) .. " : " .. "y" .. azutil:round(vecIn[2], dec) 
end


----
-- MATH
----

-- lerp(float, float, float)
--   returns a value linearly interpolated between v and t by s
--   note that if s is not constant, it will not be a 'true' linear interpolation
function azutil:lerp(v, t, s)
	return v + ((t - v)/s)
end

-- withinThresh(float, float, float)
--  returns true if a is within t of b
function azutil:withinThresh(a, b, t)
	return (math.abs(a - b) < t)
end


----
-- TABLE STUFF
----

-- tableFind(table, value)
-- returns index of the first value in tabIn equivalent to valIn
function azutil:tableFind(tabIn, valIn)
	for i, v in pairs(tabIn) do
		if v == valIn then
			return i
		end
	end
end

-- warning: this operates on the table passed to it, rather than returning a duplicate
-- I should probably make this return an operated-on duplicate but apparently copying is complicated
-- warning: table.remove is not efficient, so neither is this. be wary of frequent use on large tables
-- chkRmvTab(table, function())
-- 	runs shouldRemove() on each entry in a table, then 
-- 	removes each entry for which shouldRemove() was true
function azutil:chkRmvTab(tableIn, shouldRemove)
	local toRemove = {}
	for i, v in ipairs(tableIn) do
		if checkFunction(v) then 
			toRemove[v] = true
		end
	end
	
	local iter = 1
	while iter <= #tableIn do
		if toRemove[tableIn[iter]] then
			table.remove(tableIn, iter)
		else
			iter = iter + 1
		end
	end
end

---- 
-- MISC
----

-- round(float, float)
-- 	returns a string of num rounded to dec decimals
function azutil:round(num, dec)
	return string.format("%." .. (dec or 0) .. "f", num)
end


-- Requires animator context!
-- playSoundSafe(string, float)
-- 	plays a sound without crashing if the sound isn't defined
function azutil:playSoundSafe(sound, loopsIn)
	local loops = loopsIn or 0
	if animator.hasSound(sound) then
		animator.playSound(sound, loops)
	else 
		sb.logWarn("azutil: tried to play undefined sound <" .. sound .. ">")
	
		--sb.logWarn("azbeamfireheat: Item <" .. tostring(item.name)
		--.. "> tried to play undefined sound <" .. sound .. ">") 
	end
end

