# Gym Leader Rush+ audit

## Compared implementations

The supplied archive was compared with the existing `Gym-Leader-Shuffle`, `Randomized-Gym-Challenge`, `Red-Plus-Scaling-Core`, and `Red-Plus-Randomization-Core` repositories. It was also checked against the current Gen1Recomp source at `/home/ubuntu/upload/gen1recomp-upstream`, including `src/world/OverworldController.lua`, `src/inventory/Badges.lua`, `src/render/TextBox.lua`, `src/ui/ShopMenu.lua`, `src/ui/gen2/MartMenu.lua`, and `src/core/gen2/FlagNames.lua`.

## What Rush+ does better

Rush+ has the strongest single-save state machine: it separates the Rush choice from the optional shuffle choice, preserves the physical gym's reward owner, waits for the native reward seam before warping, and includes the Gen 2 Johto-to-Kanto continuation. It also keeps a persistent shuffle mapping and a destination-level party projection rather than mutating the source trainer tables globally.

## What the existing cores do better

The existing Scaling Core has a cleaner separation between party composition and level policy, while the existing challenge code relies more directly on native badge/reward state. The safer combined design is therefore to let Rush+ identify the physical gym and visiting source, then compose a scaling provider or apply the destination level curve once, rather than letting two independent `trainer.party` wrappers compete by registration order. Rush+ already follows that principle for its shuffle path; future work should expose the scaling provider explicitly if the standalone cores are installed together.

## Bugs fixed in 0.3.1

The submitted archive did not parse because an extra `end` preceded `shuffledTrainerPartyFallback`. The Gen 2 script rewrite was also effectively unscoped. The starter detector rejected non-vanilla species even though the project uses random starters and species expansion. Gen 1 badge detection required a boolean even though the engine writes numeric inventory counts. Gen 2 `flag.changed` uses numeric IDs, so string-only reward matching could miss a completed gym. Finally, Gen 2 was routed through the Gen 1 `ShopMenu.new` constructor; it now uses the native Gen 2 `MartMenu` with a temporary standard-mart shelf.

The TM inventory scan also referenced an undefined `item` variable. That did not always crash because the ID-prefix branch short-circuited, but it prevented item records with machine metadata from being discovered.

## Current limitation

The code uses the requested `engine_internals` permission for live NPC renderer replacement and script-command compatibility. Those seams should be rechecked when Gen1Recomp changes its internal renderer or script VM. The repaired source passes syntax validation, but it still needs an actual Red and Gold/Crystal in-game test for every progression handoff.
