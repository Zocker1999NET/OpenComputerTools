local tArgs = { ... }
local com = require("component")
local term = require("term")
local ev = require("event")
local fs = require("filesystem")
local computer = require("computer")
local function write(t)
	io.write(tostring(t or ""))
end
local function print(t)
	write(tostring(t or "").."\n")
end
local function invokeOnAll(typ,...)
	local ret = true
	for a,_ in component.list(typ) do
		local r = component.invoke(...)
		if r == nil or type(r) == "boolean" then
			ret = ret and (r or false)
		end
	end
	return ret
end
local m = {}
for k,v in pairs({"open","close","broadcast"}) do
	m[v] = function(...) invokeOnAll("modem",v,...) end
end
local function waitFor(time,port,pass,sender)
	time = time + computer.upTime()
	while 1 do
		local eD = { pS(time - computer.upTime()) }
		if not eD[1] then
			return nil
		elseif eD[1] == "modem_message" and eD[4] == (port or eD[4]) and eD[6] == (pass or eD[6]) and eD[3] == (sender or eD[3]) then
			return eD
		end
	end
end

print("NetBoot Bios Server")
print("by zocker1999net")
print()
write("Bootfile : ")
local path = tostring(tArgs[1])
if path then
	print(path)
else
	path = term.read()
	if not path then return false,"No path given" end
end
if not fs.exists(path) or fs.isDirectory(path) then
	print("File does not exist! Requests will not be answered until file exists.")
end
write"Request  : "
local req = tostring(tArgs[2])
if req then
	print(req)
else
	req = term.read()
	if not req then return false,"no request given" end
end
write"Password : "
local pass = tostring(tArgs[2])
if pass then
	print(pass)
else
	pass = term.read()
	if not pass then return false,"no password given" end
end
print()
print("Search for servers using request \""..req.."\" and password \""..pass.."\" ...")
m.open(68)
m.broadcast(67,req)
local eD = waitFor(5,68,pass)
m.close(68)
if eD then
	print("Find another server!")
	print("Cannot host a second server with same configuration!")
	return false,"configuration already used"
end

m.open(67)
event.listen("modem_message",function(...)
	local eD = {...}
	if eD[4] == 67 and eD[6]==req then
		local rec,sen = eD[2],eD[3]
		if not fs.exists(path) then
			return nil
		end
		local file,err = io.open(path,"r")
		if not file then
			print("Error while opening file: "..tostring(err))
			return nil
		end
		local buffer = ""
		for line in file:lines() do
			buffer = buffer..line
		end
		file:close()
		local parts = {}
		local partsCount = 0
		local maxLength = com.invoke(rec,"maxPacketSize")-4-pass:len()
		while buffer:len() > 0 do
			partsCount = partsCount + 1
			parts[partsCount] = buffer:sub(1,maxLength)
			buffer = buffer:sub(maxLength + 1)
		end
		local function listener(...)
			local eD = {...}
			if eD[2] == rec and eD[3] == sen and eD[4] == 68 and eD[6] == pass then
				com.invoke(rec,"send",sen,68,pass,parts[eD[7]])
			end
		end
		com.invoke(rec,"send",sen,68,pass,partsCount)
		event.listen("modem_message",listener)
		event.timer(10, function()
			parts = nil
			event.ignore("modem_message",listener)
		end)
	end
end)

return true