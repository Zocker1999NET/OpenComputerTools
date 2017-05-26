local com = component
local droneID = com.list("robot")()
local d = {}
for k,v in pairs(com.methods(droneID)) do
    d[k] = function(...) com.invoke(droneID,k,...) end
end

local sides = {[0]="down","up","back","forward","right","left"}
for k = 0,5,1 do
    local v = sides[k]
    sides[v] = k
end
sides.toRot = {[2]=2,[3]=0,[4]=1,[5]=-1}
function sides.getSide(s)
    if type(s) == "number" then
        if s < 0 then s = 0 end
        if s > 5 then s = 5 end
        return math.floor(s)
    elseif type(s) == "string" then
        return (type(sides[s]) == "number" and sides[s]) or nil
    end
    return nil
end
local function fn(n,m,s)
    d[n] = function(...) return com.invoke(droneID,sides.getSide(s),...) end
end
for k,v in pairs({"down","up","back","forward"}) do
    fn(v,"move",k-1)
end
fn("turnLeft","turn",false)
fn("turnRight","turn",true)
d.turnAround = function() return d.turnRight() and d.turnRight() end
for _,n in pairs({"compare","compareFluid","detect","drop","suck","swing","place","use"}) do
    d[n.."Native"] = d[n]
    for k,v in pairs({"Down","Up","Back","","Right","Left"}) do
        fn(n..v,n,k-1)
    end
end
function d.turnTo(s)
    return d.turnRight()
end

for _,s in pairs({"forward","right","left","back"}) do
    if not d.detect(s) then
        d.turnTo(s)
        if d.forward()
    end
end