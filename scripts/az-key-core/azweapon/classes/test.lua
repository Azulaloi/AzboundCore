test = {

}

function test:init()
	--sb.logInfo("class test init")
	--if self.weapon:checkAz() then sb.logInfo("weapon true") end
	
	--sb.logInfo("test class mt " .. tostring(getmetatable))
	--sb.logInfo(tostring(gunLoad.testval))
	--sb.logInfo(tostring(gunLoad.weapon:checkAz()))
	
	--gunLoad.weapon:test()
	--sb.logInfo(tostring(getPrimaryAbility())) 
	sb.logInfo(gunLoad.weapon:testReturn())
end

addClass("test", 1)