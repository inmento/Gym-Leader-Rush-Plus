# Changelog

## 2026-10-06 — Gen1Recomp 0.3.57 compatibility refresh
- Raised the manifest engine requirement to `>=0.3.57` while preserving any existing upper bound.
- Audited the Gen1Recomp v0.3.54–v0.3.57 release and source diff; no Gen 1/Gen 2 public hook or Mod API change used by this mod required a Lua code change.
- This is a compatibility metadata/documentation refresh; gameplay behavior, save formats, assets, and progression rules are unchanged.

## 0.3.2 — Startup prompt crash fix

- Fixed the crash after answering YES to the Gym Leader Rush prompt. The callback previously referenced `promptShuffle` before its local declaration, so Lua resolved it as a nil global. The function is now forward-declared and assigned safely.
- This fixes `main.lua:1217: attempt to call global 'promptShuffle' (a nil value)`.

## 0.3.1 — Gen1Recomp 0.3.51 compatibility repair

This release was compared against the supplied Gym Leader Rush+ archive, the existing Gym Leader Shuffle, Randomized Gym Challenge, Red+ Scaling Core, and Red+ Randomization Core implementations, and the current Gen1Recomp source/API.

### Fixed

- Removed the stray control-flow terminator that made the submitted `main.lua` fail Lua parsing at the Gen 2 script hook.
- Scoped the legacy Gen 2 script-command rewrite to Gen 2. Gen 1 no longer registers a Gen 2-only script hook.
- Allowed any Pokémon species received in Oak's or Elm's lab to arm the post-dex Rush prompt. This keeps the prompt compatible with Random Starter, Crystal 251, and other species-expansion mods.
- Accepted both boolean and numeric Gen 1 badge inventory values. Gen1Recomp writes gym badge rewards as `1` in `save.inventory`.
- Added numeric Gen 2 `flag.changed` support using the current `src.core.gen2.FlagNames` tables, while retaining named-event compatibility.
- Used the Gen 2 `MartMenu` contract for Gold, Silver, and Crystal. Gen 1 continues to use `ShopMenu`.
- Fixed the TM scan's undefined `item` local, so machine records can be detected even when their IDs are not prefixed with `TM`.

### Validation

- All Lua files pass `lua5.4` syntax loading.
- The source is aligned to Gen1Recomp Mod API 2 and the 0.3.51 public hook/event contracts.
- In-game validation is still required because the sandbox does not run the full Love2D Gen1Recomp host.

## 0.3.0

See README for the earlier supplied archive's documented changes.
