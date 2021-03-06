local math = require("math")
local fs = require("filesystem")
local ser = require("serialization")
local com = require("component")
local event = require("event")

local function lookUpAddresses(tab)
	local n = 0
	local tI = {}
	for k,v in pairs(tab) do
		n = n + 1
		tI[n] = k
	end
	for i = 1,n,1 do
		local v = tab[tI[i]]
		if type(v) == "string" then
			local a = com.get(v)
			if not a then
				error("Device starting with "..v.." not found!")
			end
			tab[tI[i]] = a
		end
	end
end

local function readFile(path)
	path = tostring(path)
	local file,err = io.open(path,"r")
	if not file then
		error("Error while opening file ''"..path.."': "..tostring(err),1)
	end
	local buffer = ""
	for line in file:lines() do
		buffer = buffer..line
	end
	file:close()
	return buffer
end

print("Load config ...")
local config = ser.unserialize(readFile("/home/secDoors.cfg"))
local gpus = {}
local lastGPU = 0
local gpuCount = 0
local screens = {}
lookUpAddresses(config.mainCom)
lookUpAddresses(config.gpus)
for k,v in pairs(config.doors) do
	lookUpAddresses(v)
end
for k,v in pairs(config.gpus) do
	gpus[k] = com.proxy(v)
	gpuCount = gpuCount + 1
end
local indexChange = {"screen1","screen2","forAll1","forAll2","rsBlock","rsSide"}
for n,t in pairs(config.doors) do
	t.name = n
	for k,v in pairs(indexChange) do
		t[v] = t[k]
	end
end
for t,a in pairs(config.mainCom) do
	a = com.get(a)
	if not a then
		error("Component not found: "..tostring(config.mainCom[t]))
	end
	com.setPrimary(t,a)
end
com.gpu.bind(com.screen.address)
for n,t in pairs(config.doors) do
	screens[t.screen1] = n
	screens[t.screen2] = n
end

print("Close all doors ...")

local function changeOutput(tab,out)
	com.invoke(tab.rsBlock,"setOutput",tab.rsSide,(out and 15) or 0)
	return true
end

for n,t in pairs(config.doors) do
	print(" "..n)
	changeOutput(t,false)
end

print("Initialize screens ...")

local function drawScreen(screen,state)
	local g
	for k,v in pairs(gpus) do
		if v.getScreen() == screen then
			g = v
			break
		end
	end
	if not g then
		lastGPU = lastGPU + 1
		if lastGPU > gpuCount then
			lastGPU = 1
		end
		g = gpus[lastGPU]
	end
	g.bind(screen)
	local s = com.proxy(screen)
	if not s.isOn() then
		s.turnOn()
	end
	local sx,sy = s.getAspectRatio()
	if sx == 3 then
		g.setResolution(38,5)
	elseif sx == 1 then
		g.setResolution(10,5)
	end
	sx,sy = g.getResolution()
	local col = 0xE1E1E1 -- Nothing
	if state == -1 then
		g.setBackground( 0x505050)
		g.fill(1,1,sx,sy," ")
	elseif state == 1 then -- Accepted
		col = 0x006D00
	elseif state == 2 then -- Rejected
		col = 0xFF0000
	end
	g.setBackground(col)
	for y = 1,sy,1 do
		for x = ((((y + 1) % 2) * 2) + 1),sx,4 do
			g.fill(x,y,2,1," ")
		end
	end
end

for k,v in pairs(config.doors) do
	drawScreen(v.screen1,-1)
	drawScreen(v.screen2,-1)
end

print("Configure Background Service ...")

local function eventCallback(...)
	local eD = {...}
	local door = screens[eD[2]]
	if not door then
		return
	end
	door = config.doors[door]
	local forAll = ((door.screen1 == eD[2] and door.forAll1) or (door.screen2 == eD[2] and door.forAll2))
	local allowed = forAll == true
	if not allowed and eD[6] then
		local pl = config.players[eD[6]]
		if type(pl) == "table" then
			allowed = pl[door.name] == true
		elseif pl == true then
			allowed = true
		end
	end
	if allowed then
		drawScreen(eD[2],1)
		changeOutput(door,true)
		event.timer(1.5, function()
			changeOutput(door,false)
			drawScreen(eD[2],(forAll and 1) or 0)
		end)
	else
		drawScreen(eD[2],2)
		event.timer(1.5, function()
			drawScreen(eD[2],(forAll and 1) or 0)
		end)
	end
end
event.listen("touch",eventCallback)

print("System set up!")
