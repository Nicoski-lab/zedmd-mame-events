-- Burst-aware score finder. Env: ZLO,ZHI (hex), ZSTRIDE (1/2/4), ZSNAP(1)
local LO=tonumber(os.getenv("ZLO")); local HI=tonumber(os.getenv("ZHI"))
local STR=tonumber(os.getenv("ZSTRIDE") or "2")
local sp=manager.machine.devices[":maincpu"].spaces["program"]
local W={}
for _,p in pairs(manager.machine.ioport.ports) do for n,fld in pairs(p.fields) do
  if n=="Coin 1" then W.coin=fld elseif n=="1 Player Start" then W.start=fld
  elseif n=="P1 Button 1" then W.fire=fld elseif n=="P1 Button 2" then W.b2=fld
  elseif n=="P1 Left" then W.left=fld elseif n=="P1 Right" then W.right=fld
  elseif n=="P1 Up" then W.up=fld elseif n=="P1 Down" then W.down=fld end
end end
local function s(f,v) if f then f:set_value(v and 1 or 0) end end
local function rd(a) if STR==1 then return sp:read_u8(a) elseif STR==2 then return sp:read_u16(a) else return sp:read_u32(a) end end
-- sample schedule
local SAMPLES={}
for t=1500,5100,300 do SAMPLES[t]=true end
local snaps={}  -- snaps[addr] = {v1,v2,...}
local order={}
local f=0
_G.scan2=emu.add_machine_frame_notifier(function()
  f=f+1
  s(W.coin,(f>300 and f<5200) and (f%300<10))
  s(W.start,(f>500 and f<5400) and (f%200<10))
  if f>600 then
    s(W.fire,true); s(W.b2,(f%240<6))            -- fire + occasional bomb/jump
    local ph=math.floor(f/40)%4
    s(W.left,ph==0); s(W.right,ph==2); s(W.up,(f%150<70)); s(W.down,(f%150>=70 and f%150<90))
  end
  if f==4000 and os.getenv("ZSNAP")=="1" then manager.machine.video:snapshot() end
  if SAMPLES[f] then
    for a=LO,HI-4,STR do
      local t=snaps[a]; if not t then t={}; snaps[a]=t; order[#order+1]=a end
      t[#t+1]=rd(a)
    end
  end
  if f==5400 then
    -- analyze: non-decreasing, total>0, bursty (some zero-deltas AND some big), not constant
    local res={}
    for _,a in ipairs(order) do
      local t=snaps[a]; local n=#t
      if n>=8 then
        local ok=true; local zero=0; local nz=0; local total=t[n]-t[1]; local maxd=0
        for i=2,n do local d=t[i]-t[i-1]
          if d<0 then ok=false break end
          if d==0 then zero=zero+1 else nz=nz+1; if d>maxd then maxd=d end end
        end
        if ok and total>0 and total<0x2000000 and zero>=2 and nz>=1 then
          res[#res+1]={a,total,zero,nz,maxd}
        end
      end
    end
    table.sort(res,function(x,y) return x[3]>y[3] end)  -- most zero-deltas (burstiest) first
    for i=1,math.min(#res,18) do local r=res[i]
      emu.print_info(string.format("ZB 0x%06x total=%d zeros=%d nz=%d maxd=%d", r[1],r[2],r[3],r[4],r[5]))
    end
    emu.print_info("ZB done n="..#res)
  end
end)
