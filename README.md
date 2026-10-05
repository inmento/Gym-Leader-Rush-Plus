# Gym Leader Rush + Shuffle 0.3.1

All-in-one Gen1Recomp API 2 mod combining Gym Leader Rush with the core Gym Leader Shuffle mechanics.

## Rush

After the starter is received and the Pokédex has been obtained, the mod asks whether to start the Gym Leader Rush first, then asks whether to enable the optional Gym Leader Shuffle. Both answers are taken before any rush teleport occurs. These are separate per-save choices: choosing Rush=NO and Shuffle=YES leaves Shuffle enabled for normal play. If both are enabled:

- Gen 1: Pewter -> Cerulean -> Vermilion -> Celadon -> Fuchsia -> Saffron -> Cinnabar -> Viridian.
- Gen 2: Falkner -> Bugsy -> Whitney -> Morty -> Chuck -> Jasmine -> Pryce -> Clair, then Victory Road/E4.
- After the first Gen 2 Hall of Fame sequence, the player can continue through the eight Kanto gyms, then Victory Road/E4 again.
- A successful gym battle sends the player directly to the next physical gym.
- The physical gym keeps its own badge/TM/progression identity.
- EXP awarded while the rush is active scales upward with rush progress.
- The existing Gym Guide NPC inside the destination Gym opens a Rush progression shop immediately after their normal leader-identification dialogue.
- Victory Road and Elite Four progression are left to the imported game rather than being rewritten.

## Integrated Shuffle

The shuffle is part of this mod; the separate Gym Leader Shuffle mod is not required.

- Persistent per-save derangement of gym leaders. The new-game prompt controls whether the shuffle is enabled for that save.
- Visiting leader sprite/presentation follows the shuffled leader.
- Visiting leader party is scaled to the physical gym's vanilla level curve and party size.
- Optional shuffled gym NPC roster, sprites, trainer identity, and scaled parties.
- Optional move randomization with physical-gym-type preference, native STAB preference, and a damaging-move safeguard.
- Physical gym remains the owner of badge/TM/reward state.
- Gen 2 uses the numeric trainer-class records required by the current Gold/Silver/Crystal data model.
- A one-use spoiler action can display the saved physical-gym -> visiting-leader mapping.

## Options

- SHUFFLE DEFAULT AT NEW GAME (default OFF; controls the initial cursor on the optional Shuffle prompt)
- SHUFFLE GYM NPCS (default ON)
- SHUFFLE LEADER MOVESETS (default OFF)
- MATCH PHYSICAL GYM TYPE (default ON)
- ALLOW NATIVE STAB (default ON)
- ENSURE DAMAGING MOVE (default ON)
- SHUFFLE HELD ITEMS (default OFF; Gen 2)
- OPEN SHUFFLE SPOILER (action)
- SHOW EXP MULTIPLIER (default OFF)

## Installation

Import the ZIP through Gen1Recomp's **Import mod .zip** action, or extract the `gym_leader_rush/` directory into the game's `mods/` directory.

Do not install the standalone Gym Leader Shuffle mod at the same time: both mods intentionally alter the same gym trainer/map systems.

## Prompt behavior

The startup questions use Gen1Recomp's native dialogue textbox with the native YES/NO choice overlay. The order is Rush first, then Shuffle. Both choices are confirmed before Rush starts or teleports. Shuffle is per-save and can be accepted even when Rush is declined.

## Testing note

This archive fixes the submitted Lua branch syntax error and is statically assembled against Gen1Recomp 0.3.51's documented Mod API 2 surface and current engine source. It was not executed against a local Love2D Gen1Recomp runtime in this build environment, so in-game validation is still required.



## 0.3.0 fixes

- Gen 1 leader and gym-trainer talk scripts are no longer replaced; native badge, TM, defeat-flag, and post-battle reward chains remain intact.
- Gym victory tracking now listens for the native `flag.changed` reward seam and keeps a 3-second / 60-step fallback window instead of discarding a delayed badge write after two checks.
- Gen 1 badge ownership uses the engine's actual inventory badge entries; Gen 2 checks the separate Johto and Kanto badge stores.
- Shuffled NPC sprites are only rebuilt when their sprite actually changes, and the mod no longer reapplies them every overworld step.
- Shuffled trainer parties are cached for the full engagement so repeated `trainer.party` lookups cannot fall back to vanilla.
- Startup prompting now also reacts directly to the Pokédex acquisition flag, with numeric starter species resolved through the Pokémon registry.
- Gym-statue source data is no longer mutated globally.
- Gen 2 gym arrival warps resolve from the arrival map's own warp data, preventing the Seafoam/Blaine out-of-bounds landing.
- Shuffle options are defined in one option set; spoiler handling no longer writes the option tables directly.
- Gen 2 TM stock accepts both numeric and named TM identifiers.
- B on the Johto Hall-of-Fame continuation prompt now cleanly declines the Kanto continuation.
- Corrected the Gen 2 STORM/MINERAL badge-bit ordering.

## 0.2.5 fixes

- Restored destination-Gym leader scaling from the original Gym Leader Shuffle implementation: party size and each destination level are preserved, with level-based de-evolution/evolution applied.
- Restored shuffled ordinary Gym trainer sprites and identities, including map-object persistence so reloaded NPCs keep their assigned source sprite.
- Leader and trainer battles now have a fallback party-scaling path for engine builds where `trainer.party` resolves before the interaction event reaches the mod bus.
- Gym Guide shop opens on `script.ended` immediately after the Guide's normal dialogue, instead of waiting for the player to take another field step.
- Gym Guide stock is now a Rush progression shop rather than the exact local mart inventory: basic supplies come first, then stronger healing/capture/status items, evolution stones/vitamins, progressive TMs, and late-rush HMs.

## 0.2.9 fixes

- Startup confirmation order is now Rush first, then Shuffle.
- Startup choices use the native interactive YES/NO ChoiceBox path rather than an automatic text advance.
- Both startup answers are completed before Rush starts or teleports to its first gym.
- Shuffled gym NPCs now rebuild their live overworld renderer when their source trainer sprite is assigned, matching the current engine renderer path.

## 0.2.7 fixes

- Added Pokémon Crystal to the supported game list and runtime guard.
- FireRed, LeafGreen, Emerald, and unsupported Gen 3 targets remain excluded.
