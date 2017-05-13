local cT = component.type
local cL = component.list
local cP = component.proxy
local cI = component.invoke

local function cID(dT)
	return cL(dT)()
end

function bI(address,method,...)
	local result = table.pack(pcall(cI,address,method,...))
	if not result[1] then
		return nil, result[2]
	else
		return table.unpack(result,2,result.n)
	end
end
boot_invoke = bI

local eeprom = cID("eeprom")
bI(eeprom,"setLabel","EEPROM (Lua Bios with NetBoot)")
computer.getBootAddress = function()
	local d = bI(eeprom,"getData")
	if d:len() >= 36 then
		return d:sub(1,36)
	else
		return nil,"Data corrupted"
	end
end
computer.setBootAddress = function(d,public,private)
	if d == nil then
		d = ""
	end
	d = component.get(d)
	if d == nil then
		return false
	end
	local t = cT(d)
	if t == "modem" and public and private then
		d = d..tostring(public)..tostring(private)
	end
	return (d ~= nil and bI(eeprom,"setData",d)) or false
end

local screen = cID("screen")
local gpu = cID("gpu")
if gpu and screen then
	bI(gpu, "bind", screen)
	bI(g,"setResolution",50,16)
end
local y = 1
local function print(t)
	t = tostring(t)
	if y == 16 then
		bI(g,"copy",1,2,50,15,0,-1)
		bI(g,"fill",1,16,50,1," ")
	else
		y = y + 1
	end
	bI(g,"set",1,y,t)
end

print("Lua BIOS with NetBoot")
print("by zocker1999net")
computer.pullSignal(3)

local function tryLoadFrom(add)
	local t = cT(add)
	if t == "filesystem" then
		local handle, reason = bI(add, "open", "/init.lua")
		if not handle then
			return nil, reason
		end
		local buffer = ""
		repeat
			local data, reason = bI(add, "read", handle, math.huge)
			if not data and reason then
				return nil, reason
			end
			buffer = buffer .. (data or "")
		until not data
		bI(add, "close", handle)
		return load(buffer, "=init")
	elseif t == "modem" then

	end
end
local init, reason
if computer.getBootAddress() then
	init, reason = tryLoadFrom(computer.getBootAddress())
end
if not init then
	computer.setBootAddress()
	for add in component.list("filesystem") do
		init, reason = tryLoadFrom(add)
		if init then
			computer.setBootAddress(add)
			break
		end
	end
	--[[for add in component.list("modem") do
		init, reason = tryLoadFrom(add)
		if init then
			computer.setBootAddress(add)
			break
		end
	end]]
end
if not init then
	error("no bootable medium found" .. (reason and (": " .. tostring(reason)) or ""), 0)
end
computer.beep(1000, 0.2)
if g then
	--g.setResolution(g.maxResolution())
end
init()