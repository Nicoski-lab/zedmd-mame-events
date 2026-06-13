-- Full work-RAM dump for offline brute-force of the score address.
local LO,HI = 0x6000,0x7000
local sp = manager.machine.devices[":maincpu"].spaces["program"]
local LOG = "/userdata/system/zedmd-mame/dkdump.log"
local f=0
_G.dk = emu.add_machine_frame_notifier(function()
  f=f+1
  if f%300==0 then
    local fh=io.open(LOG,"a")
    if fh then
      fh:write("DUMP f="..f.." ")
      for a=LO,HI-1 do fh:write(string.format("%02x", sp:read_u8(a))) end
      fh:write("\n"); fh:close()
    end
  end
end)
