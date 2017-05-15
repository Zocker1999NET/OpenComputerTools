local math = require("math")
local fs = require("filesystem")
local ser = require("serialization")
local com = require("component")

local function lookUpAddresses(tab)
	local n = 0
	local tI = {}
	for k,v in pairs(tab) do
		n = n + 1
		tI[n] = k
	end
	for i = 1,n,1 do
		local a = com.get(tab[tI[i]])
		if not a then
			error("Device starting with "..v.." not found!")
		end
		tab[tI[i]] = a
	end
end

local function changeOutput(dev,out)
	dev = com.get(dev)
	if not dev then
		return false
	end
	for s = 1,5,1 do
		com.invoke(dev,"setOutput",s,(out and 15) or 0)
	end
	return true
end

local function readFile(path)
	path = tostring(path)
	local file,err = io.open(path,"r")
	if not file then
		error("Error while opening file ''"..path.."': "..tostring(err),1)
	end
	local buffer = ""
	repeat
		local data,reason = file:read(math.huge)
		if not data and reason then
			error("Error while reading file ''"..path.."': "..reason,1)
		end
		buffer = buffer..data
	until not d
	file:close()
	return buffer
end

local config = ser.unserialize(readFile("/home/secDoors.cfg"))
lookUpAddresses(config.main)
for k,v in pairs(config.gpus) do
	lookUpAddresses(v)
end
for k,v in pairs(config.doors) do
	lookUpAddresses(v)
end
print(ser.serialize(config))
if true then return end

for t,a in pairs(config.mainCom) do
	com.setPrimary(t,com.get(a))
end
for n,t in pairs(config.doors) do
	changeOutput(t[2],true)
end
