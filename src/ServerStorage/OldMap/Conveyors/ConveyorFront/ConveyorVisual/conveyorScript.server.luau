local Speed = script.Parent.Speed.Value

while true do 
	script.Parent.Velocity = script.Parent.CFrame.LookVector*Speed
	wait(0.1)
end

