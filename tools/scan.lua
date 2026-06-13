-- Env: ZLO,ZHI (hex window), ZSTRIDE (1/2/4), ZSNAP (1=snapshot mid-run)
local LO=tonumber(os.getenv("ZLO")); local HI=tonumber(os.getenv("ZHI"))
local STR=tonumber(os.getenv("ZSTRIDE") or "2")
local sp=manager.machine.devices[":maincpu"].spaces["program"]
local W={coin=nil,start=nil,fire=nil,left=nil,right=nil,up=nil}
for _,p in pairs(manager.machine.ioport.ports) do for n,fld in pairs(p.fields) do
  if n=="Coin 1" then W.coin=fld elseif n=="1 Player Start" then W.start=fld
  elseif n=="P1 Button 1" then W.fire=fld elseif n=="P1 Left" then W.left=fld
  elseif n=="P1 Right" then W.right=fld elseif n=="P1 Up" then W.up=fld end
end end
local function s(f,v) if f then f:set_value(v and 1 or 0) end end
local function rd(a) if STR==1 then return sp:read_u8(a) elseif STR==2 then return sp:read_u16(a) else return sp:read_u32(a) end end
local A,B={},{}
local f=0
_G.scan=emu.add_machine_frame_notifier(function()
  f=f+1
  s(W.coin,(f>300 and f<4500) and (f%300<10))
  s(W.start,(f>500 and f<5000) and (f%200<10))
  if f>600 then s(W.fire,true); local ph=math.floor(f/45)%4; s(W.left,ph==0); s(W.right,ph==2); s(W.up,(f%160<60)) end
  if f==3500 and os.getenv("ZSNAP")=="1" then manager.machine.video:snapshot() end
  if f==3000 then for a=LO,HI-4,STR do A[a]=rd(a) end
  elseif f==4500 then for a=LO,HI-4,STR do B[a]=rd(a) end
  elseif f==6000 then
    local hits=0
    for a=LO,HI-4,STR do
      local va,vb,vc=A[a],B[a],rd(a)
      if va and vb and vb>va and vc>vb and (vb-va)~=(vc-vb) and vc<0x2000000 then
        emu.print_info(string.format("ZSCAN 0x%06x %d %d %d", a,va,vb,vc)); hits=hits+1
        if hits>60 then break end
      end
    end
    emu.print_info("ZSCAN done hits="..hits)
  end
end)
