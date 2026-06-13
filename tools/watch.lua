-- Live score-address finder: run while a HUMAN plays. Logs bursty-increasing
-- candidates to watch.log every ~10s. Per-game RAM window below.
local WIN = {
  dkong    = {lo=0x6000, hi=0x6300, stride=1},
  bombjack = {lo=0x8000, hi=0x9100, stride=1},
  aerofgt  = {lo=0xff9000, hi=0xffc400, stride=2},
}
local LOG="/userdata/system/zedmd-mame/watch.log"
local rom=emu.romname()
local w=WIN[rom]
if not w then return end
local sp=manager.machine.devices[":maincpu"].spaces["program"]
local function rd(a) if w.stride==1 then return sp:read_u8(a) elseif w.stride==2 then return sp:read_u16(a) else return sp:read_u32(a) end end
local function logw(m) local fh=io.open(LOG,"a"); if fh then fh:write(os.date("%H:%M:%S ")..m.."\n"); fh:close() end end
logw("WATCH start rom="..rom.." win=0x"..string.format("%x",w.lo).."-0x"..string.format("%x",w.hi))

local hist={}; local order={}
local f=0
_G.watch=emu.add_machine_frame_notifier(function()
  f=f+1
  if f%240==0 then  -- sample every ~4s of play
    for a=w.lo,w.hi-4,w.stride do
      local t=hist[a]; if not t then t={}; hist[a]=t; order[#order+1]=a end
      t[#t+1]=rd(a); if #t>30 then table.remove(t,1) end
    end
    if f%960==0 then  -- analyze + log every ~16s
      local res={}
      for _,a in ipairs(order) do local t=hist[a]; local n=#t
        if n>=5 then local ok=true; local z=0; local nz=0
          for i=2,n do local d=t[i]-t[i-1]; if d<0 then ok=false break elseif d==0 then z=z+1 else nz=nz+1 end end
          if ok and (t[n]-t[1])>0 and t[n]<0x2000000 and z>=1 and nz>=1 then
            res[#res+1]={a, t[n], z, nz} end
        end
      end
      table.sort(res,function(x,y) return x[3]>y[3] end)
      local line="CANDIDATES: "
      for i=1,math.min(#res,6) do line=line..string.format("0x%06x(v=%d,z=%d,nz=%d) ",res[i][1],res[i][2],res[i][3],res[i][4]) end
      logw(line.." [n="..#res.."]")
    end
  end
end)
