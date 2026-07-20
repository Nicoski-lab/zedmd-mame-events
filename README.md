# zedmd-mame-events

Real-time **in-game event animations on a ZeDMD dot-matrix marquee**, driven by MAME's score.
Shoot down a plane in *1942*, kill a boss Galaga, clear a challenge stage — and a matching
animated GIF fires on your arcade cabinet's DMD marquee, sized to what you just did.

Built for **Batocera + standalone MAME + ZeDMD**, entirely in MAME's built-in Lua engine.
No patched MAME, no extra daemon, no Windows — unlike the pinball-world tools it's inspired by
(DOFLinx / DOF2DMD), this runs natively on a Linux arcade cabinet.

## How it works

```
standalone MAME (running the game)
  └─ autoboot Lua script (zedmd_events.lua)
       ├─ reads the game's score from RAM every frame
       ├─ on a score jump, maps the delta → an animation tier
       └─ os.execute("dmd-play -f <gif> --once --overlay &")
            └─ dmd-play → dmdserver → ZeDMD panels
```

The `--once --overlay` flags make `dmd-play` play the GIF once, then **restore the previous
marquee** automatically — so the animation is a brief overlay on top of your normal marquee art.

Score deltas are decoded to real points (packed-BCD or one-digit-per-byte, depending on the game)
and matched against per-game tier tables, so a small kill plays a small explosion and a boss kill
plays a big one — the same mapping philosophy as the DOFLinx `.MAME` community files.

## Requirements

- **Batocera** (developed on v43.1) or any Linux setup with:
- **Standalone MAME** with Lua scripting (`-autoboot_script`) — **not** a libretro core (sandboxed, no Lua/memory access).
- **ZeDMD** (or any DMD) reachable via Batocera's `dmd-play` / `dmdserver`.
- **128×32 animated GIFs** for your games — see "Artwork" below.

## Install (Batocera)

1. Copy `zedmd_events.lua` to the cabinet, e.g. `/userdata/system/zedmd-mame/zedmd_events.lua`.
2. For each supported game, drop a one-line `<rom>.ini` into MAME's config dir
   (`/userdata/system/configs/mame/`) — see `examples/agallet.ini`:
   ```
   autoboot_script          /userdata/system/zedmd-mame/zedmd_events.lua
   ```
3. Route those games to **standalone MAME** in `/userdata/system/batocera.conf`:
   ```
   mame["agallet.zip"].emulator=mame
   mame["agallet.zip"].core=mame
   ```
4. Launch the game. Test headless first with `ZEDMD_DRYRUN=1` (logs intended fires instead of
   sending to the panel) — see `docs/INSTALL.md`.

## Supported games (validated on MAME 0.285)

| ROM | Game | Art used |
|-----|------|----------|
| `mspacman`| Ms. Pac-Man     | **13 tiers** — per-ghost (200/400/800/1600) + every fruit |
| `galaga`  | Galaga          | dedicated galaga ship/boss/challenge animations |
| `dkong`   | Donkey Kong     | dedicated dkong explosion/bonus animations |
| `agallet` | Air Gallet      | generic explosions, sized by kill |
| `1941`    | 1941            | 1942/1943-series explosions + bonus |
| `19xx`    | 19xx            | 1942-series explosions |

Adding more is a ~10-minute job per game — see `docs/ADDING-GAMES.md`. The `tools/` scripts
find and validate a game's score address automatically.

## Artwork

**This repo does not include any GIFs.** Bring your own 128×32 art. Point the script's
`GIFDIR` at your folder (default `/userdata/system/pixelcade-master/mameoutput/`).

The tier tables reference filenames from the community Pixelcade art set
(<https://github.com/alinke/pixelcade>); note Pixelcade's own artwork is licensed for use on
Pixelcade hardware. The cleanest path for a DIY ZeDMD is **custom 128×32 GIFs you make yourself** —
the format is trivial (128×32 GIF) and the mapping in the script just names files.

## Credits

- Score-address + tier-mapping concept derived from the **DOFLinx** `.MAME` community files.
- ZeDMD / `dmd-play` / `dmdserver` are part of Batocera.

## License

MIT — see [LICENSE](LICENSE). Applies to the code in this repo only, not to any artwork.
