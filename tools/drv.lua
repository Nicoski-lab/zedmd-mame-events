-- autopilot: spray coin/start across boot, hold fire + weave; then load production plugin
local W={}
for _,p in pairs(manager.machine.ioport.ports) do for n,fld in pairs(p.fields) do
  if n=="Coin 1" then W.coin=fld elseif n=="1 Player Start" then W.start=fld
  elseif n=="P1 Button 1" then W.fire=fld elseif n=="P1 Button 2" then W.b2=fld
  elseif n=="P1 Left" then W.left=fld elseif n=="P1 Right" then W.right=fld
  elseif n=="P1 Up" then W.up=fld end
end end
local function s(f,v) if f then f:set_value(v and 1 or 0) end end
local f=0
_G.drv=emu.add_machine_frame_notifier(function()
  f=f+1
  s(W.coin,(f>300 and f<4500) and (f%300<10))
  s(W.start,(f>500 and f<5000) and (f%200<10))
  if f>600 then s(W.fire,(f%12<6)); s(W.b2,(f%240<6))
    local ph=math.floor(f/45)%4; s(W.left,ph==0); s(W.right,ph==2); s(W.up,(f%160<60)) end
end)
dofile("/userdata/system/zedmd-mame/zedmd_events.lua")
