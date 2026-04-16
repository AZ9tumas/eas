--// SERVICES \\--
local ts = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local UIBlur = Lighting:WaitForChild("UIBlur")
local UICC = Lighting:WaitForChild("UICC")

--// VARIABLES \\--

-- Settings;
local tweenTime = 0.3
local frames = {} -- objects that have been tweened, alternative to :GetAttribute()
local openFrames = {}

--// FUNCTIONS \\--

local function GetProperties(frame)
	local size, pos, status = nil, nil, nil
	if frames[frame] ~= nil then
		return frames[frame][1], frames[frame][2], frames[frame][3]
	else
		pos = frame:GetAttribute("Position")
		size = frame:GetAttribute("Size")
		if size == nil then size = frame.Size end
		if pos == nil then pos = frame.Position end
		frames[frame] = {size, pos, "Available"}
		return size, pos, "Available"
	end
end

-----------------------

local t = {}

function t:RichStroke(text)
	return '<stroke color="#3C3C3C" joins="round" thickness="2" transparency="0">'..text..'</stroke>'
end

function t:BlurBG(mode)
	UIBlur.Enabled = true
	if mode == false then
		if UIBlur.Size == 0 then return end
		--UIBlur.Size = 12
		ts:Create(UIBlur, TweenInfo.new(0.3), {Size = 0}):Play()
	else
		if UIBlur.Size == 6 then return end
		--UIBlur.Size = 0
		ts:Create(UIBlur, TweenInfo.new(0.3), {Size = 6}):Play()
	end
end

function t:DimBG(mode)
	return
	--[[
		UICC.Enabled = true
	if mode == false then
		if UICC.Brightness == 0 then return end
		--UICC.Brightness = -0.05
		--ts:Create(UICC, TweenInfo.new(0.3), {Brightness = 0}):Play()
	else
		if UICC.Brightness == -0.02 then return end
		--UICC.Brightness = 0
		--ts:Create(UICC, TweenInfo.new(0.3), {Brightness = -0.02}):Play()
	end
	--]]
end

function t:FuturisticOpen(frame, setTime)
	if setTime == nil then setTime = tweenTime end
	local size, pos, status = GetProperties(frame)
	if pos and size and status == "Available" then
		frames[frame][3] = "Tweening"

		local centerPos = UDim2.new(
			pos.X.Scale + (size.X.Scale / 2), 0,
			pos.Y.Scale + (size.Y.Scale / 2), 0
		)
		local middleLeftPos = UDim2.new(
			pos.X.Scale, 0,
			pos.Y.Scale + (size.Y.Scale / 2), 0
		)
		local middleLeftSize = UDim2.new(size.X.Scale, 0, 0.005, 0)

		frame.Size = UDim2.new(0.005, 0, 0.005, 0)
		frame.Position = centerPos
		frame.Visible = true

		coroutine.wrap(function()
			frame:TweenSizeAndPosition(
				middleLeftSize, middleLeftPos,
				Enum.EasingDirection.Out, Enum.EasingStyle.Quad,
				setTime / 2, true
			)
			wait((setTime / 2) + 0.05)
			frame:TweenSizeAndPosition(
				size, pos,
				Enum.EasingDirection.Out, Enum.EasingStyle.Quad,
				setTime / 2, true
			)
			wait(setTime / 2)
			frames[frame][3] = "Available"
		end)()
		return true
	else
		return false
	end
end


function t:FuturisticClose(frame, setTime)
	if setTime == nil then setTime = tweenTime end
	local size, pos, status = GetProperties(frame)
	if pos and size and status == "Available" then
		frames[frame][3] = "Tweening"

		local centerPos = UDim2.new(
			pos.X.Scale + (size.X.Scale / 2), 0,
			pos.Y.Scale + (size.Y.Scale / 2), 0
		)
		local middleLeftPos = UDim2.new(
			pos.X.Scale, 0,
			pos.Y.Scale + (size.Y.Scale / 2), 0
		)
		local middleLeftSize = UDim2.new(size.X.Scale, 0, 0.005, 0)

		coroutine.wrap(function()
			frame:TweenSizeAndPosition(
				middleLeftSize, middleLeftPos,
				Enum.EasingDirection.Out, Enum.EasingStyle.Quad,
				setTime / 2, true
			)
			wait((setTime / 2) + 0.05)
			frame:TweenSizeAndPosition(
				UDim2.new(0.005, 0, 0.005, 0), centerPos,
				Enum.EasingDirection.Out, Enum.EasingStyle.Quad,
				setTime / 2, true
			)
			wait(setTime / 2)
			frame.Visible = false
			frames[frame][3] = "Available"
		end)()
		return true
	else
		return false
	end
end


function t:OpenOutwards(frame, setTime, easingStyle)
	local EasingStyle = easingStyle or Enum.EasingStyle.Quad
	if setTime == nil then setTime = tweenTime end
	local size, pos, status = GetProperties(frame)
	if pos and size and status == "Available" then -- 'available' acts as a debounce to prevent people from spamming opening & closing
		frames[frame][3] = "Tweening"
		frame.Size = UDim2.new(0.005,0,0.01,0)
		frame.Visible = true
		frame:TweenSize(size, Enum.EasingDirection.Out, EasingStyle, setTime, true)
		coroutine.wrap(function() 
			wait(setTime) -- make sure it doesn't delay the script the function was called from
			frames[frame][3] = "Available" -- deactivate debounce
		end)()
		return true
	else
		return false
	end
end

function t:OpenEFT2(frame, setTime, easingStyle)
	local EasingStyle = easingStyle or Enum.EasingStyle.Quad
	if setTime == nil then setTime = tweenTime end
	local size, pos, status = GetProperties(frame)
	if pos and size and status == "Available" then -- 'available' acts as a debounce to prevent people from spamming opening & closing
		frames[frame][3] = "Tweening"
		--frame.Size = UDim2.new(0.005,0,0.01,0)
		local justUnderPos = pos.Y.Scale*1.4
		local setPos = UDim2.fromScale(pos.X.Scale, justUnderPos)
		frame.Position = setPos
		frame.Visible = true
		--frame:TweenSize(size, Enum.EasingDirection.Out, EasingStyle, setTime, true)
		frame:TweenPosition(pos, Enum.EasingDirection.Out, Enum.EasingStyle.Back, setTime, true)
		coroutine.wrap(function() 
			wait(setTime) -- make sure it doesn't delay the script the function was called from
			frames[frame][3] = "Available" -- deactivate debounce
		end)()
		return true
	else
		return false
	end
end


function t:CloseEFT2(frame, setTime)
	if setTime == nil then setTime = tweenTime end
	local size, pos, status = GetProperties(frame)
	if pos and size and status == "Available" then
		frames[frame][3] = "Tweening"
		frame.Visible = false
		frames[frame][3] = "Available"
		return true
	else
		return false
	end
end

function t:CloseInwards(frame, setTime)
	if setTime == nil then setTime = tweenTime end
	local size, pos, status = GetProperties(frame)
	if pos and size and status == "Available" then
		frames[frame][3] = "Tweening"
		frame:TweenSize(UDim2.new(0.01,0,0.01,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, setTime, true)
		coroutine.wrap(function() 
			wait(setTime * 0.9)
			frame.Visible = false
			wait(setTime * 0.1) -- make sure it doesn't delay the script the function was called from
			frames[frame][3] = "Available" -- deactivate debounce
		end)()
		return true
	else
		return false
	end
end

function t:ButtonBounce(frame, setTime, depth)
	if depth == nil then depth = 1 end
	if setTime == nil then setTime = tweenTime end
	local size, pos, status = GetProperties(frame)
	if pos and status == "Available" then
		frames[frame][3] = "Tweening"
		frame.Position = pos
		coroutine.wrap(function()
			frame:TweenPosition(UDim2.new(pos.X.Scale,0,pos.Y.Scale + (0.0125 * depth),0),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,setTime/2,true)
			wait(setTime/2)
			frame:TweenPosition(pos,Enum.EasingDirection.Out,Enum.EasingStyle.Quad,setTime/2,true)
			wait(setTime/2)
			frames[frame][3] = "Available"
			return true
		end)()
	else
		return false
	end
end

function t:ButtonInward(frame, setTime, diviser)
	if diviser == nil then diviser = 8 end
	if setTime == nil then setTime = tweenTime end
	local size, pos, status = GetProperties(frame)
	if status == "Available" then
		frames[frame][3] = "Tweening"
		local alteredPos = UDim2.new(pos.X.Scale+(size.X.Scale/diviser/2),0,(pos.Y.Scale+(size.Y.Scale/diviser/2)),0)
		local alteredSize = UDim2.new(size.X.Scale-(size.X.Scale/diviser),0,(size.Y.Scale-(size.Y.Scale/diviser)),0)
		frame.Position = pos
		frame.Size = size
		coroutine.wrap(function()
			frame:TweenSizeAndPosition(alteredSize,alteredPos,Enum.EasingDirection.Out,Enum.EasingStyle.Quad,setTime/2,true)
			wait(setTime/2)
			frame:TweenSizeAndPosition(size,pos,Enum.EasingDirection.Out,Enum.EasingStyle.Quad,setTime/2,true)
			wait(setTime/2)
			frames[frame][3] = "Available"
		end)()
	end
end

function t:ButtonInward2(frame, setTime, diviser)
	if diviser == nil then diviser = 8 end
	if setTime == nil then setTime = tweenTime end
	local size, pos, status = GetProperties(frame)
	if status == "Available" then
		frames[frame][3] = "Tweening"
		local alteredSize = UDim2.new(size.X.Scale-(size.X.Scale/diviser),0,(size.Y.Scale-(size.Y.Scale/diviser)),0)
		frame.Position = pos
		frame.Size = size
		coroutine.wrap(function()
			frame:TweenSize(alteredSize,Enum.EasingDirection.Out,Enum.EasingStyle.Quad,setTime/2,true)
			wait(setTime/2)
			frame:TweenSize(size,Enum.EasingDirection.Out,Enum.EasingStyle.Quad,setTime/2,true)
			wait(setTime/2)
			frames[frame][3] = "Available"
		end)()
		return true
	else
		return false
	end
end

function t:ButtonProduct(frame, setTime)
	if setTime == nil then setTime = tweenTime end
	local size, pos, status = GetProperties(frame)
	if status == "Available" then
		frames[frame][3] = "Tweening"
		local alteredPos = UDim2.new(pos.X.Scale+(size.X.Scale/8/2),0,(pos.Y.Scale+(size.Y.Scale/8/2)),0)
		local alteredSize = UDim2.new(size.X.Scale,0,(size.Y.Scale-(size.Y.Scale/8)),0)
		frame.Position = pos
		frame.Size = size
		coroutine.wrap(function()
			frame:TweenSizeAndPosition(alteredSize,alteredPos,Enum.EasingDirection.Out,Enum.EasingStyle.Quad,setTime/2,true)
			wait(setTime/2)
			frame:TweenSizeAndPosition(size,pos,Enum.EasingDirection.Out,Enum.EasingStyle.Quad,setTime/2,true)
			wait(setTime/2)
			frames[frame][3] = "Available"
		end)()
	end
end



return t
