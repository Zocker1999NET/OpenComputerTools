--1
component=(component or require("component"))
computer=(computer or require("computer"))
local z="Lua Bios with just NetBoot"
local b=computer.beep
local uT=computer.uptime
local pS=computer.pullSignal
local tU=table.unpack
local cT=component.type
local cL=component.list
local cP=component.proxy
local cI=component.invoke
local function cID(dT)return cL(dT)()end
function bI(...)local r={pcall(cI,...)}if not r[1] then
return nil,r[2]
else
return tU(r,2,r.n)end
end
local eR=cID("eeprom")bI(eR,"setLabel",z)local function gBA()local d=bI(eR,"getData")if d:len()>36 then
local p=38
while d:sub(p,p)~= "|" do
p=p+1
end
return d:sub(1,36),d:sub(38,p-1),d:sub(p+1)else
return nil,"Data corrupted"
end
end
local function sBA(a,b,c)
    if cT(a or "")=="modem" and b and c then
        a=a.."|"..b.."|"..c
        return bI(eR,"setData",a.."|"..b.."|"..c) or false
    else
        return false
    end
end
computer.getBootAddress=gBA
computer.setBootAddress=sBA
local function wF(t,e,f,g,h)
	t=t+uT()while 1 do
		local d={pS(t-uT())}
		if not d[1] then return
		elseif d[1]==e and d[4]==(f or d[4]) and d[6]==(g or d[6]) and d[3]==(h or d[3]) then return d end
	end
end
local g
local scr=cID("screen")local gp=cID("gpu")if gp and scr then g=cP(gp)g.bind(scr)bI(scr,"turnOn")g.setResolution(50,16)g.setBackground(0)g.setForeground(0xFFFFFF)else for i=1,5,1 do b(1500,.1)end end
local y=1
local function pr(t)g.set(1,y,t)y=math.min(y+1,16)end
local function cl(s)s=s or 1 g.fill(1,s,50,16," ")y=s end
local function key(t,...)local k={}
	for _k,v in pairs({...})do k[v]=1 end
	while 1 do
		local e=wF(t,"key_down")
		if not e then return elseif k[e[4]] then return e[4] end
	end
end
local function iS()
	local z=y
	local t=""
	while 1 do
		local e=wF(10,"key_down")
		if not e then return else
			if e[3]==8 and t:len()>0 then t=t:sub(1,t:len()-1)elseif e[3]==13 then break elseif e[3]>31 then t=t..string.char(e[3])end
			y=z
			pr(">"..t..(" "):rep(49-t:len()))
		end
	end
	return t
end
local function tLF(a,b,c)
	local t=cT(a)
	local l=""
	if t=="modem" then
		local m=cP(a)
		m.open(68)
		m.broadcast(67,b)
		local y="modem_message"
		local d=wF(5,y,68,c)
		if not d then m.close(68) return nil,"server not found" end
		local r=d[3]
		for i=1,d[7],1 do
			m.send(r,68,c,i)
			d=wF(5,y,68,c,r)
			if not d then m.close(68) return nil,"connection lost" end
			l=l..d[7]
		end
		m.close(68)
	end
	return (l~="" and load(l,"=init")) or nil,"device not found"
end
if g then
	cl()
	pr(z)
	pr"by zocker1999net"
	if cID("keyboard") then
		pr""
		pr"[CTRL] for boot menu"
		b(1000,.5)
		if key(.5,29)then
			cl()
			pr"Which source do you like to boot from? (10sec)"
			pr""
			local i=0
			local k={}
			local l={}
			for a in cL("modem")do
				i=i+1 k[i]=i+1 l[i+1]=a pr("("..i..") "..a)
			end
			if i==0 then error("no bootable medium found",0)end
			k=key(10,tU(k))
			if not k then return end
			local b
			local c
			cl(3)pr"Modem:"
			pr(">"..l[k])pr"Request:"
			b=iS()pr"Password:"
			c=iS()
			sBA(l[k],b,c)
		end
	end
end
local i,r
if gBA()then i,r=tLF(gBA())end
if not i then
error("no bootable medium found"..(r and (": "..tostring(r)) or ""),0)end
b(1000,.2)i()