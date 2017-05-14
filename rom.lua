--12
local component=component if not component then component=require("component")end
local computer=computer if not computer then computer=require("computer")end
local tmp=computer.tmpAddress()local b=computer.beep
local uT=computer.uptime
local cT=component.type
local cL=component.list
local cP=component.proxy
local cI=component.invoke
local function cID(dT)return cL(dT)()end
function bI(address,method,...)local result=table.pack(pcall(cI,address,method,...))if not result[1] then
return nil, result[2]
else
return table.unpack(result,2,result.n)end
end
local eeprom=cID("eeprom")bI(eeprom,"setLabel","Lua Bios with NetBoot")local function gBA()local d=bI(eeprom,"getData")if d:len()==36 then
return d:sub(1,36)elseif d:len()> 36 then
local p=38
while d:sub(p,p)~= "|" do
p=p + 1
end
return d:sub(1,36),d:sub(38,p-1),d:sub(p+1)else
return nil,"Data corrupted"
end
end
local function sBA(d,pub,pr)if not d then
d=""
end
if not cT(d)then
return false
end
if cT(d)=="modem" and pub and pr then
d=d.."|"..tostring(pub).."|"..tostring(pr)end
return (d ~= nil and bI(eeprom,"setData",d))or false
end
computer.getBootAddress=gBA
computer.setBootAddress=sBA
local g
local screen=cID("screen")local gpu=cID("gpu")if gpu and screen then g=cP(gpu)g.bind(screen)cI(screen,"turnOn")g.setResolution(50,16)g.setBackground(0)g.setForeground(0xFFFFFF)else for i=1,5,1 do b(1500,.1)end end
local y=1
local function pr(t)if g then
t=tostring(t)g.set(1,y,t)y=math.min(y+1,16)end
end
local function cls(s)s=s or 1 if g then g.fill(1,s,50,16," ")y=s end end
local function key(t,...)local k={}
for _k,v in pairs({...})do k[v]=1 end
t=uT()+ t
while t > uT()do
local e={computer.pullSignal(t-uT())}
if e[1]=="key_down" and k[e[4]] then return e[4] end
end
end
local function iS()local z=y
local t=""
while true do
local e={computer.pullSignal(10)}
if not e[1] then return elseif e[1] == "key_down" then
if e[3]==8 and t:len()>0 then t=t:sub(1,t:len()-1)elseif e[3]==13 then break
elseif e[3]>31 then t=t..string.char(e[3])end
y=z
print(">"..t..(" "):rep(49-t:len()))end
end
return t
end
local function tLF(a,b,c)
	local t=cT(a)
	if t=="filesystem" then
		local h,r=bI(a,"open","/init.lua")
		if not h then
			return nil,r
		end
		local l=""
		repeat
			local d,r=bI(a,"read",h,math.huge)
			if not d and r then
				return nil,r
			end
			l=l..(d or "")
		until not d
		bI(a,"close",h)
		return load(l,"=init")
	elseif t=="modem" then

	end
end
local function rB(n)cls(3)local i=0
local k={}
local l={}
for a in cL(n and "modem" or "filesystem")do
if n or bI(a,"exists","/init.lua")then i=i+1 k[i]=i+1 l[i+1]=a pr("("..i..") "..a..(n and (" "..bI(a,"getLabel")) or ""))end
end
if i==0 then error("no bootable medium found",0)end
k=key(10,table.unpack(k))if not k then return end
local b
local c
if n then
cls(3)print"Modem"
print(">"..a)print"Request:"
b=iS()print"Password:"
c=iS()end
sBA(l[k],b,c)tLF(l[k],b,c)()end
local function sB()if g then
pr"Which source do you like to boot from? (10sec)"
pr""
pr"(1) Boot from local filesystem"
pr"(2) Boot from network"
local k=key(10,2,3)if not k then return end
rB(k==3)end
end
pr"Lua Bios with NetBoot"
pr"by zocker1999net"
if cID("keyboard")then
pr""
pr"Press [CTRL] for boot menu"
b(1000,.5)if key(.5,29)then
cls()sB()computer.shutdown()return nil
end
end
local i,r
if gBA()then
i,r=tLF(gBA())end
if not i then
sBA()for add in component.list("filesystem")do
i,r=tLF(add)if i then
sBA(add)break
end
end
end
if not i then
error("no bootable medium found"..(r and(": "..tostring(r))or""),0)end
b(1000,.2)i()