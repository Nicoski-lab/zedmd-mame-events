-- zedmd_events.lua : MAME score-delta -> ZEDMD animations, faithful to Pixelcade.
-- Score is BCD-decoded (forward) to decimal points; per-game SC tables copied from
-- the DOFLinx/Pixelcade .MAME maps (only the FF_PC marquee animations). DRYRUN=1 = log only.
local GIFDIR="/userdata/system/pixelcade-master/mameoutput/"
local LOGFILE="/userdata/system/zedmd-mame/zedmd.log"
local DRY=(os.getenv("ZEDMD_DRYRUN")=="1")

-- tiers: {minDelta,maxDelta,gif} in DECODED points (BCD). delay = ms between animations.
local GAMES = {
  digdug = { addr=0x8414, bytes=3, mult=1, rev=true, delay=3000, tiers={
    {200,500,"digdug_pooka.gif"}, {501,1000,"digdug_fygar.gif"} }},
  mspacman = { addr=0x4e80, bytes=4, mult=1, rev=true, delay=3000, tiers={
    {50,60,"pacman_powerpellet.gif"}, {100,100,"pacman_cherry.gif"},
    {200,210,"pacman_ghost200.gif"}, {300,300,"pacman_strawberry.gif"},
    {400,410,"pacman_ghost400.gif"}, {500,500,"pacman_orange.gif"},
    {700,700,"mspacman_pretzel.gif"}, {800,810,"pacman_ghost800.gif"},
    {1000,1000,"pacman_apple.gif"}, {1600,1610,"pacman_ghost1600.gif"},
    {2000,2000,"mspacman_pear.gif"}, {5000,5000,"mspacman_bannana.gif"},
    {10000,10000,"mspacman_bannana.gif"} }},
  dkong = { addr=0x60b2, bytes=3, mult=1, delay=1000, tiers={
    {100,200,"generic_100.gif"}, {300,300,"dkong_explosion.gif"}, {600,5000,"dkong_bonus.gif"} }},
  galaga = { addr=0x83f8, bytes=8, mult=1, digits=true, delay=5000, tiers={
    {50,160,"galaga_shipinflight-exploding.gif"}, {400,400,"galaga_bossinflight-exploding.gif"},
    {800,800,"galaga_bossinflight-exploding.gif"}, {1600,1600,"galaga_bossinflight-exploding.gif"},
    {2000,9500,"galaga_challengenotperfect.gif"}, {10000,10000,"galaga_challengeperfect.gif"} }},
  agallet = { addr=0x10028a, bytes=4, mult=1, delay=1500, tiers={
    {10,100,"generic_explosion1.gif"}, {110,990,"generic_explosion6.gif"},
    {1000,19990,"generic_explosion-long1.gif"} }},
  ["1941"] = { addr=0xff0db6, bytes=4, mult=1, delay=2000, tiers={
    {100,100,"1942_explosion-small.gif"}, {500,500,"1943kai_explosion.gif"},
    {1000,1000,"generic_explosion-long1.gif"}, {2000,2000,"generic_explosion-long2.gif"},
    {5000,5000,"1943kai_explosion.gif"}, {10000,10000,"generic_explosion-long1.gif"},
    {80000,80000,"pacman_strawberry.gif"} }},
  ["19xx"] = { addr=0xff8306, bytes=4, mult=1, delay=2000, tiers={
    {100,290,"1942_explosion-small.gif"}, {1700,10000,"generic_explosion-long1.gif"} }},
}

local function log(m) local fh=io.open(LOGFILE,"a"); if fh then fh:write(os.date("%H:%M:%S ")..m.."\n"); fh:close() end end
local rom=emu.romname()
local cfg=GAMES[rom]
if not cfg then return end
local delayframes = math.floor(cfg.delay*60/1000 + 0.5)
log("ACTIVE rom="..rom.." addr=0x"..string.format("%x",cfg.addr).." bcd delay="..delayframes.."f"..(DRY and " DRYRUN" or ""))

local sp=manager.machine.devices[":maincpu"].spaces["program"]
local function readscore()
  if cfg.digits then  -- one decimal digit per byte, LSD first (0x24 = blank)
    local v=0
    for i=cfg.bytes-1,0,-1 do
      local b=sp:read_u8(cfg.addr+i)
      v = v*10 + ((b<=9) and b or 0)
    end
    return v*cfg.mult
  end
  if cfg.rev then  -- packed BCD, little-endian (least-significant pair at lowest addr)
    local v=0
    for i=cfg.bytes-1,0,-1 do
      local b=sp:read_u8(cfg.addr+i)
      v = v*100 + math.floor(b/16)*10 + (b%16)
    end
    return v*cfg.mult
  end
  -- packed BCD, forward (big-endian)
  local v=0
  for i=0,cfg.bytes-1 do
    local b=sp:read_u8(cfg.addr+i)
    v = v*100 + math.floor(b/16)*10 + (b%16)
  end
  return v*cfg.mult
end
local function fire(gif,d) log("FIRE "..gif.." delta="..d)
  if not DRY then os.execute("dmd-play -f \""..GIFDIR..gif.."\" --once --overlay >/dev/null 2>&1 &") end end

local last,cooldown=nil,0
_G.zedmd_ev_sub=emu.add_machine_frame_notifier(function()
  if cooldown>0 then cooldown=cooldown-1 end
  local v=readscore()
  if last then
    local d=v-last
    if d>0 and d<=200000 and cooldown==0 then
      for _,t in ipairs(cfg.tiers) do if d>=t[1] and d<=t[2] then fire(t[3],d); cooldown=delayframes; break end end
    end
  end
  last=v
end)
