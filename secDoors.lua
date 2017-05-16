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

local function changeOutput(tab,out)
	com.invoke(tab.rsBlock,"setOutput",tab.rsSide,(out and 15) or 0)
	return true
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
lookUpAddresses(config.mainCom)
for k,v in pairs(config.gpus) do
	lookUpAddresses(v)
end
for k,v in pairs(config.doors) do
	lookUpAddresses(v)
end
local indexChange = {"screen1","screen2","isForAll1","isForAll2","rsBlock","rsSide"}
for _,t in pairs(config.doors) do
	for k,v in pairs(indexChange) do
		t[v] = t[k]
	end
end
for t,a in pairs(config.mainCom) do
	com.setPrimary(t,com.get(a))
end

print("Open all doors ...")
for n,t in pairs(config.doors) do
	print(" "..n)
	changeOutput(t,true)
end
