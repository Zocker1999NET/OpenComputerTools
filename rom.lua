--V2
local component = component
if not component then
	component = require("component")
end
local computer = computer
if not computer then
	computer = require("computer")
end
local b = computer.beep
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
bI(eeprom,"setLabel","Lua Bios with NetBoot")
computer.getBootAddress = function()
	local d = bI(eeprom,"getData")
	if d:len() == 36 then
		return d:sub(1,36)
	elseif d:len() > 36 then
		local p = 38
		while d:sub(p,p) ~= "|" do
			p = p + 1
		end
		return d:sub(1,36),d:sub(38,p-1),d:sub(p+1)
	else
		return nil,"Data corrupted"
	end
end
computer.setBootAddress = function(d,pub,pr)
	if not d then
		d = ""
	end
	if not cT(d) then
		return false
	end
	if cT(d) == "modem" and pub and pr then
		d = d.."|"..tostring(pub).."|"..tostring(pr)
	end
	return (d ~= nil and bI(eeprom,"setData",d)) or false
end

local g
local screen = cID("screen")
local gpu = cID("gpu")
if gpu and screen then
	g = cP(gpu)
	g.bind(screen)
	bI(screen,"turnOn")
	g.setResolution(50,16)
	g.setBackground(0)
	g.setForeground(0xFFFFFF)
else for i=1,5,1 do b(1500,.1) end end
local y = 1
local function print(t)
	if g then
		t = tostring(t)
		if y == 16 then
			g.copy(1,2,50,15,0,-1)
			g.fill(1,16,50,1," ")
		else
			y = y + 1
		end
		g.set(1,y,t)
	end
end
------123456789.123456789.123456789.123456789.123456789
print"Lua BIOS with NetBoot"
print"by zocker1999net"
print""
print"Press [CTRL] for boot menu"
b(1000,.5)

local function tryLoadFrom(add)
	local t = cT(add)
	if t == "filesystem" then
		local h,r = bI(add, "open", "/init.lua")
		if not h then
			return nil, r
		end
		local b = ""
		repeat
			local d,r = bI(add, "read", h, math.huge)
			if not d and r then
				return nil, r
			end
			b = b..(d or "")
		until not d
		bI(add,"close",h)
		return load(b,"=init")
	elseif t == "modem" then

	end
end
local i, r
if computer.getBootAddress() then
	i, r = tryLoadFrom(computer.getBootAddress())
end
if not i then
	computer.setBootAddress()
	for add in component.list("filesystem") do
		i, r = tryLoadFrom(add)
		if i then
			computer.setBootAddress(add)
			break
		end
	end
	--[[for add in component.list("modem") do
		i, r = tryLoadFrom(add)
		if i then
			computer.setBootAddress(add)
			break
		end
	end]]
end
if not i then
	error("no bootable medium found" .. (r and (": " .. tostring(r)) or ""), 0)
end
b(1000,.2)
i()