-- Universal score-address validator + autopilot.
-- Env: ZADDR (hex), ZBYTES (3/4/8), ZREV (1=little-endian read)
local ADDR  = tonumber(os.getenv("ZADDR"))
local BYTES = tonumber(os.getenv("ZBYTES") or "4")
local REV   = (os.getenv("ZREV") == "1")
local sp = manager.machine.devices[":maincpu"].spaces["program"]

-- discover input fields by name across ALL ports
local want = {coin=nil, start=nil, fire=nil, up=nil, down=nil, left=nil, right=nil}
for _,port in pairs(manager.machine.ioport.ports) do
  for fname,field in pairs(port.fields) do
    if fname=="Coin 1" then want.coin=field end
    if fname=="1 Player Start" then want.start=field end
    if fname=="P1 Button 1" then want.fire=field end
    if fname=="P1 Up" then want.up=field end
    if fname=="P1 Down" then want.down=field end
    if fname=="P1 Left" then want.left=field end
    if fname=="P1 Right" then want.right=field end
  end
end
local function set(f,v) if f then f:set_value(v and 1 or 0) end end
local function readscore()
  local v=0
  if REV then for i=BYTES-1,0,-1 do v=v*256+sp:read_u8(ADDR+i) end
  else        for i=0,BYTES-1   do v=v*256+sp:read_u8(ADDR+i) end end
  return v
end
emu.print_info(string.format("ZVAL setup addr=0x%x bytes=%d rev=%s coin=%s start=%s fire=%s",
  ADDR,BYTES,tostring(REV),tostring(want.coin~=nil),tostring(want.start~=nil),tostring(want.fire~=nil)))

local f=0
local firstnz=nil
_G.zval_sub = emu.add_machine_frame_notifier(function()
  f=f+1
  -- spray coin & start across the whole boot window; hold fire + weave once playing
  set(want.coin,  (f>300 and f<4500) and (f%300<10))
  set(want.start, (f>500 and f<5000) and (f%200<10))
  if f>600 then
    set(want.fire,true)
    local ph=math.floor(f/45)%4
    set(want.left, ph==0); set(want.right, ph==2)
    set(want.up,  (f%160<60))
  end
  if f%150==0 then
    local v=readscore()
    if v>0 and not firstnz then firstnz=f; emu.print_info("ZVAL FIRSTNONZERO f="..f.." v="..v) end
    emu.print_info(string.format("ZVAL f=%5d v=%d", f, v))
  end
end)
