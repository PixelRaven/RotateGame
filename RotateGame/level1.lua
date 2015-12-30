-----------------------------------------------------------------------------------------
--
-- level1.lua
--
-----------------------------------------------------------------------------------------

local composer = require "composer"
local scene = composer.newScene()

-- include Corona's "physics" library
local physics = require "physics"
physics.start(); physics.pause()
physics.setPositionIterations(1280) -- Default is 3?
physics.setVelocityIterations(12) -- Default is 8?
--physics.setDrawMode("hybrid")

--------------------------------------------

-- forward declarations and other locals
local screenW, screenH = display.contentWidth, display.contentHeight
local halfW, halfH = screenW/2, screenH/2

function scene:create(event)
    --Create our "levelObjs" display group
	local sceneGroup = self.view
	levelObjs = display.newGroup()
	sceneGroup:insert(levelObjs)
	levelObjs.anchorChildren = true
	levelObjs.anchorX, levelObjs.anchorY = 0.5, 0.5
	levelObjs.x, levelObjs.y = halfW, halfH
	
	system.setAccelerometerInterval(10) -- From 10 - 100 Hz. Lower saves battery
			
	--Load Sound Effects
	local collide = audio.loadSound("collide.mp3")

	-- Create Walls
	local walls = display.newImage(levelObjs, "image.png", 240, 240)
	walls.x, walls.y = halfW, 220
	walls.myName = "walls"
	
	local BOUNCE = 0.0
	local FRICTION = 1.0
	local speed = 0 -- Speed of wall group rotation
	
	physics.addBody(walls, "static",
		{density=1.0, bounce=BOUNCE, friction=FRICTION, shape={-120,-120, 120,-120, 120,-110, -120,-110}},
		{density=1.0, bounce=BOUNCE, friction=FRICTION, shape={-120,110, 120,110, 120,120, -120,120}},
		{density=1.0, bounce=BOUNCE, friction=FRICTION, shape={-120,-120, -110,-120, -110,120, -120,120}},
		{density=1.0, bounce=BOUNCE, friction=FRICTION, shape={110,-110, 120,-110, 120,90, 110,90}},
		{density=1.0, bounce=BOUNCE, friction=FRICTION, shape={-80,80, 110,80, 110,90, -80,90}},
		{density=1.0, bounce=BOUNCE, friction=FRICTION, shape={-80,-80, -70,-80, -70,80, -80,80}},
		{density=1.0, bounce=BOUNCE, friction=FRICTION, shape={-40,-80, 110,-80, 110,-70, -40,-70}},
		{density=1.0, bounce=BOUNCE, friction=FRICTION, shape={-40,-40, 80,-40, 80,-30, -40,-30}},
		{density=1.0, bounce=BOUNCE, friction=FRICTION, shape={-40,-30, -30,-30, -30,50, -40,50}},
		{density=1.0, bounce=BOUNCE, friction=FRICTION, shape={-30,40, 80,40, 80,50, -30,50}}
	)
	
	--Add our spikes
	local obstacles = {}
	local spike = display.newImage(levelObjs, "spike.png", 24, 32)
	physics.addBody(spike, "static", {shape={-12, 16, 0, -16, 12, 16}, density=3.0, friction=0.8, bounce=0.3})
	spike.x, spike.y = 65, 314
	spike.myName = "spike"
	obstacles[0] = spike
	
	-- Create Balls
	local ball = createBall(12, 108, 120)
	local ball2
	local split = 0
				
	local function onLocalCollision(self, event)
		if event.other.myName ~= nil and event.other.myName == "spike" and split == 0 then
			split = 1
			local function splitBall(event)
				local ballX, ballY = ball.x, ball.y
				ball:removeSelf()
				ball = createBall(6, ballX-3, ballY)
				ball2 = createBall(6, ballX+3, ballY)
			end
			timer.performWithDelay(1, splitBall)
		elseif event.other.myName ~= nil and event.other.myName == "walls" then
			local vx, vy = self:getLinearVelocity()
			local v = math.min((math.abs(vx) + math.abs(vy))/300, 1)
			print("vx: " .. vx .. " vy: " .. vy .. " v: " .. v)
			if v > 0.4 then 
				audio.setVolume(v)
				local collideChannel = audio.play(collide)
			end
		end
	end

	ball.collision = onLocalCollision
	ball:addEventListener("collision", ball)

	--transition.to(walls, {time=20000, rotation=walls.rotation+720})

	local touchStartTime = 0

	local function myTouchListener(event)
		if event.phase == "began" then
			touchStartTime = event.time
			speed = 0
		elseif event.phase == "moved" then
			local a = math.atan2(event.y-(screenH-64), event.x-halfW)
			levelObjs.rotation = math.deg(a)
			physics.setGravity(math.sin(a)*9.8, math.cos(a)*9.8);
			--print("Angle: " .. a .. "Gravity X: " .. math.cos(a)*9.8 .. " Gravity Y: " .. math.sin(a)*9.8)
			--speed = (event.x - event.xStart)/(event.time - touchStartTime)
		end
		return true
	end

	--local slider = display.newRoundedRect(sceneGroup, halfW, 480, 300, 48, 16)
	local slider = display.newCircle(sceneGroup, halfW, screenH-64, 48)
	slider:setFillColor(1, 0.5, 0)
	slider:addEventListener("touch", myTouchListener)

	local function enterFrameListener(event)
		--if speed ~= 0 then
		--	walls:rotate(-5*speed)
		--	speed = 0.99*speed
		--end
	end

	Runtime:addEventListener("enterFrame", enterFrameListener)
end

function onAccelerate(event)
	print(event.name, event.xGravity, event.yGravity, event.zGravity)
	physics.setGravity(event.zGravity, event.xGravity)
end

function scene:show(event)
	local sceneGroup = self.view
	local phase = event.phase
	
	if phase == "will" then
		-- Called when the scene is still off screen and is about to move on screen
	elseif phase == "did" then
		-- Called when the scene is now on screen
		-- 
		-- INSERT code here to make the scene come alive
		-- e.g. start timers, begin animation, play audio, etc.
		physics.start()
		Runtime:addEventListener("accelerometer", onAccelerate)
	end
end

function scene:hide(event)
	local sceneGroup = self.view
	
	local phase = event.phase
	
	if event.phase == "will" then
		-- Called when the scene is on screen and is about to move off screen
		--
		-- INSERT code here to pause the scene
		-- e.g. stop timers, stop animation, unload sounds, etc.)
		Runtime:removeEventListener("accelerometer", onAccelerate)
		physics.stop()
	elseif phase == "did" then
		-- Called when the scene is now off screen
	end	
	
end

function scene:destroy(event)

	-- Called prior to the removal of scene's "view" (sceneGroup)
	-- 
	-- INSERT code here to cleanup the scene
	-- e.g. remove display objects, remove touch listeners, save state, etc.
	local sceneGroup = self.view
	
	package.loaded[physics] = nil
	physics = nil
end

function createBall(r, x, y)
	local ball
	if r == 6 then
		ball = display.newImage(levelObjs, "ball-half.png", r*2, r*2)
	else
		ball = display.newImage(levelObjs, "ball.png", r*2, r*2)
	end
	ball.x, ball.y = x, y
	physics.addBody(ball, {radius=r, density=1.0, bounce=0.5, friction=1.0})
	ball.isSleepingAllowed = false;
	return ball
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

-----------------------------------------------------------------------------------------

return scene