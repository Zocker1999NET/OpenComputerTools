local function write(txt)
    io.write(tostring(txt or ""))
end
local function print(txt)
    write(tostring(txt or "").."\n")
end
local ev = require("event")
local com = require("component")
local term = require("term")
local net
for a in com.list("modem") do
    if com.invoke(a,"isWireless") then
        net = com.proxy(a)
    end
end
if not net then
    print("A wireless card is needed to use this tool!")
    return
end
net.open(1)

local function sendCommand(response,...)
    net.broadcast(1,"nanomachines",...)
    while true do
        local eD = {ev.pull(5,"modem_message",nil,nil,1,nil,"nanomachines",response)}
        if not eD[1] then
            return nil
        else
            return {table.unpack(eD,8)}
        end
    end
end

local userName = ""
local mInputs = 0
local function disableAllInputs()
    print("Disable all inputs ...")
    for i = 1,mInputs,1 do
        write("#")
        local r = {}
        while r[1] ~= i or not r[2] do
            r = sendCommand("input","setInput",i,false)
            if not r then
                print("Connection lost!")
                return false
            end
        end
    end
    print()
    return true
end

print("Try to connect to nanomachines ...")
local r = sendCommand("port","setResponsePort",1)
if (not r) or r[1] ~= 1 then print("No nanomachines found!")return end
r = sendCommand("name","getName")
if not r then print("Connection lost!") return end
userName = tostring(r[1])
print("Connected to nanomachines of "..userName..".")
r = sendCommand("totalInputCount","getTotalInputCount")
if not r then print("Connection lost!") return end
mInputs = tonumber(r[1])
print("Found "..tostring(mInputs).." inputs.")
if not disableAllInputs() then return end
print("Start calibration? (Y/n)")
print(" Only "..userName.." can accept this request.")
local doCal = false
while true do
    local eD = {term.pull("key_down")}
    if eD[4] == 49 then
        break
    elseif (eD[4] == 21 or eD[4] == 28) and eD[5] == userName then
        doCal = true
        break
    end
end
if not doCal then
    print("Calibration abort!")
    disableAllInputs()
    return
end

local results = {}
