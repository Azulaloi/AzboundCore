hueshifter = {
	hue = 0,
	speed = 50
}

function hueshifter:init()
	--sb.logInfo("hueshift init")
end

function hueshifter:update(dt)
	self.hue = self.hue + (dt * self.speed) % 360
	animator.setGlobalTag("hueShift", "hueshift=" .. self.hue)
	
	sb.logInfo(tostring(self.hue))
end

addClass("hueshifter", 2)