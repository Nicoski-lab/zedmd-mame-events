# Adding a new game

A game needs three things: a **score memory address**, a **decode method**, and a **tier table**
(score-delta range → GIF). The `tools/` scripts find the first two; the DOFLinx `.MAME` files (or
your own taste) give the third.

## 1. Find a starting address
Two good sources of a candidate score address:
- **MAME `hiscore.dat`** (`/usr/bin/mame/plugins/hiscore/hiscore.dat`): `grep -A3 '^<rom>:'` —
  the high-score save region is at or near the live score.
- **DOFLinx `.MAME` files** (if you have the Pixelcade/DOFLinx set): the `[SCORE]` block's
  `S1=:maincpu|main|program|<addr>|<bytes>` line. NOTE: these were made for older MAME versions and
  the address may have drifted — always validate.

## 2. Validate it moves with the score
`tools/validate.lua` drives the game (coin/start/fire autopilot) and logs the value at a candidate
address. Env: `ZADDR` (hex), `ZBYTES` (3/4/8), `ZREV` (1 = little-endian).
```bash
ZADDR=0xff8306 ZBYTES=4 DISPLAY=:0 SDL_VIDEODRIVER=x11 SDL_AUDIODRIVER=dummy \
  mame -rompath "$RP" 19xx -video none -sound none -seconds_to_run 90 -skip_gameinfo ... \
  -autoboot_script tools/validate.lua
# look for FIRSTNONZERO and a value that climbs as you'd expect
```

## 3. If the address is wrong, scan for it
`tools/scan.lua` (3-point monotonic diff) and `tools/scan2.lua` (burst-aware: separates a bursty
score from steady timers) sweep a RAM window and rank candidates. Env: `ZLO`, `ZHI`, `ZSTRIDE`, `ZSNAP`.
```bash
ZLO=0xff0000 ZHI=0xffd000 ZSTRIDE=2 ... -autoboot_script tools/scan2.lua
```
For **skill games where the autopilot can't score** (e.g. Donkey Kong), use `tools/watch.lua` instead:
a HUMAN plays while it logs bursty-increasing candidates to `watch.log` every ~16 s.

## 4. Decode method
Most arcade scores are **packed BCD** (two decimal digits per byte). Some (e.g. Galaga) store
**one decimal digit per byte** — set `digits=true`. Byte order is usually big-endian (`forward`);
set `rev=true` for little-endian. Watch the raw bytes in the validator output to tell which:
clean round decimals after decoding = correct.

## 5. Add the entry
In `zedmd_events.lua`'s `GAMES` table:
```lua
["19xx"] = { addr=0xff8306, bytes=4, mult=1, delay=2000, tiers={
  {100,290,"1942_explosion-small.gif"},
  {1700,10000,"generic_explosion-long1.gif"} }},
```
- `tiers` = `{minDelta, maxDelta, gif}` in **decoded points**; first match wins.
- `delay` = ms between animations (cooldown), from the `.MAME` `DELAY=` or your taste.
- `digits=true` for one-digit-per-byte games; `rev=true` for little-endian.

Then add the `<rom>.ini` and the `batocera.conf` routing (see INSTALL.md), and dry-run it.

## Edge-triggered fire
Some games (Galaga) only register a *new* shot on button press-down, so a held fire = one shot.
The autopilot in `tools/drv.lua` pulses fire for this reason; it works for hold-to-fire games too.
