# Install & test

## 1. Place the script
```
scp zedmd_events.lua  root@CABINET:/userdata/system/zedmd-mame/zedmd_events.lua
```

## 2. Hook each supported game
Standalone MAME auto-reads `<rom>.ini` from its inipath (`/userdata/system/configs/mame/`).
Create one per game (see `examples/agallet.ini`):
```
autoboot_script          /userdata/system/zedmd-mame/zedmd_events.lua
```

## 3. Route the game to standalone MAME
In `/userdata/system/batocera.conf` (libretro cores are sandboxed — no Lua, won't work):
```
mame["agallet.zip"].emulator=mame
mame["agallet.zip"].core=mame
```

## 4. Point GIFDIR at your art
Edit the top of `zedmd_events.lua`:
```lua
local GIFDIR = "/userdata/system/pixelcade-master/mameoutput/"   -- your 128x32 GIF folder
```

## 5. Test headless (no panel needed)
`ZEDMD_DRYRUN=1` logs intended fires to `zedmd.log` instead of sending to the DMD.
The `tools/drv.lua` autopilot drives a game so you can validate without playing:

```bash
RP="/userdata/roms/mame;/userdata/bios/mame;/userdata/bios"
ZEDMD_DRYRUN=1 DISPLAY=:0 SDL_VIDEODRIVER=x11 SDL_AUDIODRIVER=dummy \
  mame -rompath "$RP" agallet -video none -sound none -seconds_to_run 90 -skip_gameinfo \
  -nvram_directory /tmp/nv -cfg_directory /tmp/cfg -homepath /tmp/mh \
  -autoboot_script /userdata/system/zedmd-mame/tools/drv.lua
cat /userdata/system/zedmd-mame/zedmd.log     # expect ACTIVE + FIRE lines
```

## Gotchas
- **Running MAME over SSH** needs `DISPLAY=:0 SDL_VIDEODRIVER=x11` (the SDL build has no dummy/offscreen driver).
- **Don't** launch via Batocera's `emulatorlauncher` + `timeout` in the background — `timeout` kills
  the launcher but MAME survives, and stacked instances fight over the display. Use `-seconds_to_run`
  (exits itself) for headless tests; let the cabinet's frontend manage real launches.
- The MAME Lua frame-notifier subscription must be retained in a global or it gets garbage-collected
  (the script stores it in `_G.zedmd_ev_sub`).
