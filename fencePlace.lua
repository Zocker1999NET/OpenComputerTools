local r = require("robot")

local function select()
    for i = 1,r.inventorySize(),1 do
        if r.count(i) > 0 then
            r.select(i)
        end
    end
end
local function place()
    select()
    r.placeDown()
end
local function forward(n)
    n = n or 1
    for i = 1,n,1 do
        while not r.forward() do
            os.sleep(1)
        end
    end
end
local function placeF()
    place()
    forward()
end

local function chain()
    for i = 1,10,1 do
        placeF()
    end
    place()
end

for y = 1,16,1 do
    local side = (math.fmod(y,2)) == 1 -- left/false : true/right
    for i = 1,7,1 do
        chain()
        forward(3)
    end
    chain()
    if side then
        r.turnRight()
        forward(10)
        r.turnRight()
    else
        r.turnLeft()
        forward(3)
        r.turnLeft()
    end
end