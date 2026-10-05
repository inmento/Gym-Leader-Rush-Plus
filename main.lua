-- Gym Leader Rush
-- Mod API 2
--
-- Sequential physical-gym rush for Gen 1 and Gen 2.
-- Designed to compose with Gym Leader Shuffle: the rush identifies the
-- physical gym by map/object, while the live leader name is read from the NPC.

local GameVersion = require("src.core.GameVersion")
local SpriteRenderer = require("src.render.SpriteRenderer")

return function(mod)
  local VERSION = GameVersion.get()
  local SUPPORTED_GAMES = {
    red = true,
    blue = true,
    yellow = true,
    gold = true,
    silver = true,
    crystal = true,
  }

  -- The mod is intentionally limited to the original Gen 1/Gen 2 games.
  -- Gen 3 is supported by Gen1Recomp, but this mod's map, trainer, and
  -- progression data are not authored for FireRed, LeafGreen, or Emerald.
  if not SUPPORTED_GAMES[VERSION] then
    return
  end

  local GENERATION = GameVersion.generation(VERSION)
  local GEN2 = GENERATION == 2

  local function norm(value)
    return tostring(value or ""):lower():gsub("[^%w]", "")
  end

  local function clone(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k, v in pairs(value) do out[k] = clone(v) end
    return out
  end

  local function sortedUnique(list)
    local seen, out = {}, {}
    for _, value in ipairs(list or {}) do
      if type(value) == "string" and not seen[value] then
        seen[value] = true
        out[#out + 1] = value
      end
    end
    table.sort(out)
    return out
  end

  local GEN1_GYMS = {
    { id="OPP_BROCK",     name="Brock",     sprite="SPRITE_SUPER_NERD", preBattleText="_PewterGymBrockPreBattleText", gymType="ROCK",     mapId="PEWTER_GYM",      objectIndex=1, arrival={mapId="PEWTER_CITY",    x=16, y=18}, badge="BOULDERBADGE",  badgeBit=0, shopMap="PEWTER_MART" },
    { id="OPP_MISTY",     name="Misty",     sprite="SPRITE_BRUNETTE_GIRL", preBattleText="_CeruleanGymMistyPreBattleText", gymType="WATER",     mapId="CERULEAN_GYM",    objectIndex=1, arrival={mapId="CERULEAN_CITY",  x=30, y=20}, badge="CASCADEBADGE",  badgeBit=1, shopMap="CERULEAN_MART" },
    { id="OPP_LT_SURGE",  name="Lt. Surge", sprite="SPRITE_ROCKER", preBattleText="_VermilionGymLTSurgePreBattleText", gymType="ELECTRIC", mapId="VERMILION_GYM",   objectIndex=1, arrival={mapId="VERMILION_CITY", x=12, y=20}, badge="THUNDERBADGE",  badgeBit=2, shopMap="VERMILION_MART" },
    { id="OPP_ERIKA",     name="Erika",     sprite="SPRITE_SILPH_WORKER_F", preBattleText="_CeladonGymErikaPreBattleText", gymType="GRASS",     mapId="CELADON_GYM",     objectIndex=1, arrival={mapId="CELADON_CITY",   x=12, y=28}, badge="RAINBOWBADGE",  badgeBit=3, shopMap="CELADON_MART" },
    { id="OPP_KOGA",      name="Koga",      sprite="SPRITE_KOGA", preBattleText="_FuchsiaGymKogaBeforeBattleText", gymType="POISON",      mapId="FUCHSIA_GYM",     objectIndex=1, arrival={mapId="FUCHSIA_CITY",   x=5,  y=28}, badge="SOULBADGE",     badgeBit=4, shopMap="FUCHSIA_MART" },
    { id="OPP_SABRINA",   name="Sabrina",   sprite="SPRITE_GIRL", preBattleText="_SaffronGymSabrinaText", gymType="PSYCHIC",   mapId="SAFFRON_GYM",     objectIndex=1, arrival={mapId="SAFFRON_CITY",   x=34, y=4},  badge="MARSHBADGE",    badgeBit=5, shopMap="SAFFRON_MART" },
    { id="OPP_BLAINE",    name="Blaine",    sprite="SPRITE_MIDDLE_AGED_MAN", preBattleText="_CinnabarGymBlainePreBattleText", gymType="FIRE",    mapId="CINNABAR_GYM",    objectIndex=1, arrival={mapId="CINNABAR_ISLAND",x=18, y=4},  badge="VOLCANOBADGE",  badgeBit=6, shopMap="CINNABAR_MART" },
    { id="OPP_GIOVANNI",  name="Giovanni",  sprite="SPRITE_GIOVANNI", preBattleText="_ViridianGymGiovanniPreBattleText", gymType="GROUND",  mapId="VIRIDIAN_GYM",    objectIndex=1, arrival={mapId="VIRIDIAN_CITY",  x=32, y=8},  badge="EARTHBADGE",    badgeBit=7, shopMap="VIRIDIAN_MART" },
  }

  local GEN2_JOHTO = {
    { id="FALKNER", class=1,  name="Falkner", sprite="SPRITE_FALKNER", gymType="FLYING", mapId="VIOLET_GYM",       objectIndex=1, arrival={mapId="VIOLET_CITY",      x=18, y=17}, badge="ZEPHYR",  badgeBit=0, shopMap="VIOLET_MART" },
    { id="BUGSY", class=3,    name="Bugsy",   sprite="SPRITE_BUGSY", gymType="BUG",   mapId="AZALEA_GYM",       objectIndex=1, arrival={mapId="AZALEA_TOWN",      x=10, y=15}, badge="HIVE",    badgeBit=1, shopMap="AZALEA_MART" },
    { id="WHITNEY", class=2,  name="Whitney", sprite="SPRITE_WHITNEY", gymType="NORMAL", mapId="GOLDENROD_GYM",    objectIndex=1, arrival={mapId="GOLDENROD_CITY",   x=24, y=7},  badge="PLAIN",   badgeBit=2, shopMap="GOLDENROD_MART" },
    { id="MORTY", class=4,    name="Morty",   sprite="SPRITE_MORTY", gymType="GHOST",   mapId="ECRUTEAK_GYM",     objectIndex=1, arrival={mapId="ECRUTEAK_CITY",    x=6,  y=27}, badge="FOG",     badgeBit=3, shopMap="ECRUTEAK_MART" },
    { id="CHUCK", class=7,    name="Chuck",   sprite="SPRITE_CHUCK", gymType="FIGHTING",   mapId="CIANWOOD_GYM",     objectIndex=1, arrival={mapId="CIANWOOD_CITY",    x=8,  y=43}, badge="STORM",   badgeBit=5, shopMap="CIANWOOD_MART" },
    { id="JASMINE", class=6,  name="Jasmine", sprite="SPRITE_JASMINE", gymType="STEEL", mapId="OLIVINE_GYM",      objectIndex=1, arrival={mapId="OLIVINE_CITY",     x=10, y=11}, badge="MINERAL", badgeBit=4, shopMap="OLIVINE_MART" },
    { id="PRYCE", class=5,    name="Pryce",   sprite="SPRITE_PRYCE", gymType="ICE",   mapId="MAHOGANY_GYM",     objectIndex=1, arrival={mapId="MAHOGANY_TOWN",    x=6,  y=13}, badge="GLACIER", badgeBit=6, shopMap="MAHOGANY_MART" },
    { id="CLAIR", class=8,    name="Clair",   sprite="SPRITE_CLAIR", gymType="DRAGON",   mapId="BLACKTHORN_GYM_1F",objectIndex=1, arrival={mapId="BLACKTHORN_CITY", x=18, y=11}, badge="RISING",  badgeBit=7, shopMap="BLACKTHORN_MART" },
  }

  local GEN2_KANTO = {
    { id="BROCK", class=17,     name="Brock",     sprite="SPRITE_BROCK", gymType="ROCK",      mapId="PEWTER_GYM",       objectIndex=1, arrival={mapId="PEWTER_CITY",    x=16, y=17}, badge="BOULDER", badgeBit=8, shopMap="PEWTER_MART" },
    { id="MISTY", class=18,     name="Misty",     sprite="SPRITE_MISTY", gymType="WATER",      mapId="CERULEAN_GYM",     objectIndex=2, arrival={mapId="CERULEAN_CITY",  x=30, y=23}, badge="CASCADE", badgeBit=9, shopMap="CERULEAN_MART" },
    { id="LT_SURGE", class=19,  name="Lt. Surge", sprite="SPRITE_SURGE", gymType="ELECTRIC",  mapId="VERMILION_GYM",    objectIndex=1, arrival={mapId="VERMILION_CITY", x=10, y=19}, badge="THUNDER", badgeBit=10, shopMap="VERMILION_MART" },
    { id="ERIKA", class=21,     name="Erika",      sprite="SPRITE_ERIKA", gymType="GRASS",      mapId="CELADON_GYM",      objectIndex=1, arrival={mapId="CELADON_CITY",   x=10, y=29}, badge="RAINBOW", badgeBit=11, shopMap="CELADON_MART" },
    { id="JANINE", class=26,    name="Janine",     sprite="SPRITE_JANINE", gymType="POISON",     mapId="FUCHSIA_GYM",      objectIndex=1, arrival={mapId="FUCHSIA_CITY",   x=8,  y=27}, badge="SOUL",    badgeBit=12, shopMap="FUCHSIA_MART" },
    { id="SABRINA", class=35,   name="Sabrina",    sprite="SPRITE_SABRINA", gymType="PSYCHIC",    mapId="SAFFRON_GYM",      objectIndex=1, arrival={mapId="SAFFRON_CITY",   x=34, y=3},  badge="MARSH",   badgeBit=13, shopMap="SAFFRON_MART" },
    { id="BLAINE", class=46,    name="Blaine",     sprite="SPRITE_BLAINE", gymType="FIRE",     mapId="SEAFOAM_GYM",      objectIndex=1, arrival={mapId="ROUTE_20",       x=38, y=7},  badge="VOLCANO", badgeBit=14, shopMap="CINNABAR_MART" },
    { id="BLUE", class=64,      name="Blue",       sprite="SPRITE_BLUE", gymType="VARIED",       mapId="VIRIDIAN_GYM",     objectIndex=1, arrival={mapId="VIRIDIAN_CITY",  x=32, y=7},  badge="EARTH",   badgeBit=15, shopMap="VIRIDIAN_MART" },
  }

  local GYMS = GEN2 and {} or clone(GEN1_GYMS)
  if GEN2 then
    for _, gym in ipairs(GEN2_JOHTO) do GYMS[#GYMS + 1] = gym end
    for _, gym in ipairs(GEN2_KANTO) do GYMS[#GYMS + 1] = gym end
  end

  --------------------------------------------------------------------------
  -- Integrated Gym Leader Shuffle
  --
  -- This is intentionally built into Gym Leader Rush rather than declared as
  -- a dependency.  The physical gym remains the reward/progression owner;
  -- only presentation, trainer identity, and the visiting party are shuffled.
  --------------------------------------------------------------------------
  mod.options:define({
    { key="shuffle_default", type="toggle", label="SHUFFLE DEFAULT AT NEW GAME", default=false },
    { key="shuffle_trainers", type="toggle", label="SHUFFLE GYM NPCS", default=true },
    { key="shuffle_moves", type="toggle", label="SHUFFLE LEADER MOVESETS", default=false },
    { key="shuffle_match_type", type="toggle", label="MATCH PHYSICAL GYM TYPE", default=true },
    { key="shuffle_native_stab", type="toggle", label="ALLOW NATIVE STAB", default=true },
    { key="shuffle_damage", type="toggle", label="ENSURE DAMAGING MOVE", default=true },
    { key="shuffle_held", type="toggle", label="SHUFFLE HELD ITEMS", default=false },
    { key="shuffle_spoiler", type="toggle", label="OPEN SHUFFLE SPOILER", default=false },
    { key="show_exp_multiplier", type="toggle", label="SHOW EXP MULTIPLIER", default=false },
  })

  local function shuffleList(list)
    for i = #list, 2, -1 do
      local j = (love and love.math and love.math.random and love.math.random(i)) or math.random(i)
      list[i], list[j] = list[j], list[i]
    end
  end

  local CLASS_ID = {}
  if GEN2 then
    for id, trainer in mod.content.trainers:each() do
      if type(trainer) == "table" and trainer.index ~= nil then CLASS_ID[trainer.index] = id end
    end
  end

  local function trainerRecord(id)
    if GEN2 and type(id) == "number" then id = CLASS_ID[id] or id end
    local t = mod.content.trainers:get(id)
    if type(t) ~= "table" then return nil end
    return t
  end

  local function trainerParty(class, member)
    local t = trainerRecord(class)
    if not t then return nil end
    if t.parties and t.parties[member] then return t.parties[member] end
    for _, row in ipairs(t.trainers or {}) do
      if row.index == member or row.id == member then return row.party end
    end
    return nil
  end

  local function fitSpecies(species, level)
    local pre = {}
    for id, mon in mod.content.pokemon:each() do
      for _, evo in ipairs(mon.evolutions or {}) do
        if evo.method == "LEVEL" and evo.species and evo.level then
          pre[evo.species] = { species=id, level=evo.level }
        end
      end
    end
    local cur = species
    for _=1,6 do
      local prior = pre[cur]
      if not prior or level >= prior.level then break end
      cur = prior.species
    end
    for _=1,6 do
      local mon = mod.content.pokemon:get(cur)
      local nxt, nxtLevel
      for _, evo in ipairs(mon and mon.evolutions or {}) do
        if evo.method == "LEVEL" and evo.species and evo.level and level >= evo.level
          and (not nxtLevel or evo.level < nxtLevel) then
          nxt, nxtLevel = evo.species, evo.level
        end
      end
      if not nxt then break end
      cur = nxt
    end
    return cur
  end

  local function moveMatchesType(moveId, species, gymType)
    local move = mod.content.moves:get(moveId)
    if not move then return 0, false end
    local mon = mod.content.pokemon:get(species)
    local native = false
    for _, typ in ipairs(mon and mon.types or {}) do
      if move.type == typ then native = true break end
    end
    local score = 0
    if mod.options:get("shuffle_match_type") and move.type == gymType then score = 2
    elseif mod.options:get("shuffle_native_stab") and native then score = 1 end
    return score, (move.power or 0) > 0
  end

  local function randomizedMoves(species, level, gymType)
    if not mod.options:get("shuffle_moves") then return nil end
    local pool, seen = {}, {}
    local function add(id)
      if not id or seen[id] or not mod.content.moves:get(id) then return end
      seen[id] = true
      local score, damaging = moveMatchesType(id, species, gymType)
      pool[#pool+1] = { id=id, score=score, damaging=damaging }
    end
    local mon = mod.content.pokemon:get(species)
    for _, id in ipairs(mon and mon.level1Moves or {}) do add(id) end
    for _, row in ipairs(mon and (mon.levelMoves or mon.learnset) or {}) do
      local levelRow = row.level or 1
      if levelRow <= level then add(row.move) end
    end
    for _, id in ipairs({"TACKLE","SCRATCH","POUND","QUICK_ATTACK","BITE","HEADBUTT"}) do add(id) end
    local preferred, neutral = {}, {}
    for _, row in ipairs(pool) do
      if row.score > 0 then preferred[#preferred+1] = row else neutral[#neutral+1] = row end
    end
    shuffleList(preferred); shuffleList(neutral)
    local ordered = {}
    for _, row in ipairs(preferred) do ordered[#ordered+1] = row end
    for _, row in ipairs(neutral) do ordered[#ordered+1] = row end
    local moves, used = {}, {}
    if mod.options:get("shuffle_damage") then
      for _, row in ipairs(ordered) do
        if row.damaging then moves[#moves+1] = row.id; used[row.id] = true; break end
      end
    end
    for _, row in ipairs(ordered) do
      if #moves >= 4 then break end
      if not used[row.id] then moves[#moves+1] = row.id; used[row.id] = true end
    end
    return moves
  end

  local SHUFFLE = { byId={}, byMap={}, trainerByKey={}, trainersByGym={}, vanilla={}, mapping=nil, trainerMapping=nil }
  for _, gym in ipairs(GYMS) do
    SHUFFLE.byId[gym.id], SHUFFLE.byMap[gym.mapId] = gym, gym
    local t = trainerRecord(gym.id)
    local partyIndex = gym.partyIndex or gym.member or 1
    if t and t.parties and t.parties[partyIndex] then
      SHUFFLE.vanilla[gym.id] = clone(t.parties[partyIndex])
    elseif t then
      SHUFFLE.vanilla[gym.id] = clone(trainerParty(gym.id, partyIndex) or {})
    end
    SHUFFLE.trainersByGym[gym.id] = {}
  end

  -- Gen 2 uses class/member records on map objects. Gen 1 uses trainerClass/
  -- trainerParty records. Both are converted into the same internal roster.
  for _, gym in ipairs(GYMS) do
    local map = mod.content.maps:get(gym.mapId)
    for arrayIndex, object in ipairs(map and map.objects or {}) do
      local idx = object.index or arrayIndex
      if idx ~= gym.objectIndex then
        local class, member, sprite, text, party
        if GEN2 then
          class = object.trainer and object.trainer.class
          member = object.trainer and object.trainer.member
          sprite = object.sprite
          text = object.text or (object.trainer and object.trainer.text)
        else
          class, member = object.trainerClass, object.trainerParty
          sprite, text = object.sprite, object.text
        end
        if class and member then
          party = trainerParty(class, member)
          if party then
            local rec = { key=gym.id..":"..tostring(idx), gymId=gym.id, mapId=gym.mapId,
              objectIndex=idx, class=class, member=member, sprite=sprite, text=text,
              party=clone(party) }
            SHUFFLE.trainersByGym[gym.id][#SHUFFLE.trainersByGym[gym.id]+1] = rec
            SHUFFLE.trainerByKey[rec.key] = rec
          end
        end
      end
    end
  end

  local function createShuffleMapping()
    local ids={}
    for _, gym in ipairs(GYMS) do ids[#ids+1]=gym.id end
    local fixed=true
    repeat
      shuffleList(ids); fixed=false
      for i,gym in ipairs(GYMS) do if ids[i]==gym.id then fixed=true; break end end
    until not fixed
    local map={}
    for i,gym in ipairs(GYMS) do map[gym.id]=ids[i] end
    mod.save:set("shuffle_mapping", map)
    mod.save:set("shuffle_trainer_mapping", nil)
    return map
  end

  local function shuffleEnabled()
    local enabled = mod.save:get("shuffle_enabled", nil)
    if type(enabled) == "boolean" then return enabled end
    -- Preserve the integrated-mod behavior for saves created by 0.2.1,
    -- which already have a saved shuffle mapping but no explicit choice key.
    return type(mod.save:get("shuffle_mapping", nil)) == "table"
  end

  local function shuffleMapping()
    if not shuffleEnabled() then return nil end
    local m=mod.save:get("shuffle_mapping")
    if type(m)=="table" then return m end
    return createShuffleMapping()
  end

  local function setShuffleEnabled(enabled)
    enabled = enabled == true
    mod.save:set("shuffle_enabled", enabled)
    if enabled then
      shuffleMapping()
    else
      mod.save:set("shuffle_mapping", nil)
      mod.save:set("shuffle_trainer_mapping", nil)
      mod.save:set("shuffle_held_mapping", nil)
    end
  end

  local function createTrainerMapping(leaderMap)
    if not (leaderMap and mod.options:get("shuffle_trainers")) then return nil end
    local out={}
    for _, dest in ipairs(GYMS) do
      local source=SHUFFLE.byId[leaderMap[dest.id]]
      local src=source and SHUFFLE.trainersByGym[source.id] or {}
      local dst=SHUFFLE.trainersByGym[dest.id] or {}
      if #src>0 then
        local order=clone(src); shuffleList(order)
        for i,row in ipairs(dst) do
          local sourceRow = order[i] or order[(i - 1) % #order + 1]
          if sourceRow then out[row.key]=sourceRow.key end
        end
      end
    end
    mod.save:set("shuffle_trainer_mapping", out)
    return out
  end

  local function trainerMapping()
    local lm=shuffleMapping()
    if not lm or not mod.options:get("shuffle_trainers") then return nil end
    local m=mod.save:get("shuffle_trainer_mapping")
    return type(m)=="table" and m or createTrainerMapping(lm)
  end

  local function shuffledHeldItem(key, original)
    if not (GEN2 and mod.options:get("shuffle_held") and original) then return original end
    local state=mod.save:get("shuffle_held_mapping",{})
    if state[key] then return state[key] end
    local pool={}
    for id,item in mod.content.items:each() do
      if type(id)=="string" and type(item)=="table" and item.heldEffect
        and item.heldEffect~="HELD_NONE" and item.canToss~=false
        and item.keyItem~=true and item.pocket~="KEY_ITEM" then
        pool[#pool+1]=id
      end
    end
    table.sort(pool)
    if #pool==0 then return original end
    local j=(love and love.math and love.math.random and love.math.random(#pool)) or math.random(#pool)
    state[key]=pool[j]
    mod.save:set("shuffle_held_mapping",state)
    return state[key]
  end

  local function scaledShuffleParty(sourceId, destination, sourceParty)
    local source=sourceParty or SHUFFLE.vanilla[sourceId] or {}
    local target=SHUFFLE.vanilla[destination.id] or {}
    local out={}
    for i,targetMon in ipairs(target) do
      local sourceMon=source[math.min(i,#source)] or source[1]
      if sourceMon and targetMon then
        local row=clone(sourceMon)
        row.level=targetMon.level
        row.species=fitSpecies(row.species,row.level)
        local moves=randomizedMoves(row.species,row.level,destination.gymType)
        if moves and #moves>0 then row.moves=moves end
        row.item=shuffledHeldItem((destination.id or "gym")..":"..tostring(i),row.item)
        out[#out+1]=row
      end
    end
    return out
  end

  local function scaledShuffleTrainerParty(sourceRec, destinationRec, destinationGym)
    local source = sourceRec and sourceRec.party or {}
    local target = destinationRec and destinationRec.party or {}
    local out = {}
    for i, targetMon in ipairs(target) do
      local sourceMon = source[math.min(i, #source)] or source[1]
      if sourceMon and targetMon then
        local row = clone(sourceMon)
        row.level = targetMon.level
        row.species = fitSpecies(row.species, row.level)
        local moves = randomizedMoves(row.species, row.level,
          destinationGym and destinationGym.gymType or "NORMAL")
        if moves and #moves > 0 then row.moves = moves end
        row.item = shuffledHeldItem(
          "trainer:" .. tostring(destinationRec and destinationRec.key or i),
          row.item)
        out[#out + 1] = row
      end
    end
    return out
  end

  local liveShuffleLeaders, liveShuffleTrainers = {}, {}
  local pendingShuffleLeader, pendingShuffleTrainer
  local scaledPartyCache = {}

  local function setSprite(npc, sprite)
    if not (npc and sprite) then return false end
    if npc.def and npc.def.sprite == sprite and npc.sprite then
      return true
    end
    local def = mod.content.sprites:get(sprite)
    if not def then return false end

    -- Rebuild the live renderer exactly the way the current engine's
    -- overworld map loader does. This is important for an existing NPC:
    -- changing only npc.def.sprite does not guarantee the already-created
    -- SpriteRenderer instance is replaced.
    if npc.def then npc.def.sprite = sprite end
    local ok = pcall(function()
      npc.sprite = SpriteRenderer.new(def, npc.id)
    end)
    if ok and npc.sprite then return true end

    -- Keep the runtime setter as a compatibility fallback for a host that
    -- exposes it but does not permit direct renderer replacement.
    if npc.setSpriteDef then
      local fallbackOk = pcall(function() npc:setSpriteDef(def) end)
      if fallbackOk then return true end
    end
    return false
  end

  local function patchActiveMapObject(mapId, objectIndex, sprite, class, member)
    local game = mod.game
    local world = game and (game.overworld or game.world)
    local map = world and world.map
    local objects = map and map.def and map.def.objects
    if type(objects) ~= "table" then return end
    for _, object in ipairs(objects) do
      if tonumber(object.index) == tonumber(objectIndex) then
        if sprite then object.sprite = sprite end
        if GEN2 then
          object.trainer = object.trainer or {}
          if class ~= nil then object.trainer.class = class end
          if member ~= nil then object.trainer.member = member end
        else
          if class ~= nil then object.trainerClass = class end
          if member ~= nil then object.trainerParty = member end
        end
        return
      end
    end
  end

  local function applyShuffleMap(mapId)
    local physical = SHUFFLE.byMap[mapId]
    if not physical then return end
    local lm = shuffleMapping()
    local visitor = lm and SHUFFLE.byId[lm[physical.id]] or physical

    local leaderHandle = mod.world:npc(mapId, physical.objectIndex)
    local leader = leaderHandle and leaderHandle.npc
    if leader then
      local leaderClass = GEN2 and (visitor.class or visitor.id) or visitor.id
      local leaderMember = visitor.member or visitor.partyIndex or 1
      if GEN2 then
        leader.def.trainer.class = leaderClass
        leader.def.trainer.member = leaderMember
      else
        leader.def.trainerClass = leaderClass
        leader.def.trainerParty = leaderMember
      end
      setSprite(leader, visitor.sprite or physical.sprite)
      patchActiveMapObject(mapId, physical.objectIndex,
        visitor.sprite or physical.sprite, leaderClass, leaderMember)
      liveShuffleLeaders[leader.id] = {
        npc = leader, gym = physical,
        assigned = leaderClass, party = leaderMember, visitor = visitor,
      }
    end

    local tm = trainerMapping()
    for _, dst in ipairs(SHUFFLE.trainersByGym[physical.id] or {}) do
      local h = mod.world:npc(mapId, dst.objectIndex)
      local npc = h and h.npc
      if npc then
        local sourceKey = tm and tm[dst.key]
        local src = sourceKey and SHUFFLE.trainerByKey[sourceKey]
        if src then
          if GEN2 then
            npc.def.trainer.class = src.class
            npc.def.trainer.member = src.member
          else
            npc.def.trainerClass = src.class
            npc.def.trainerParty = src.member
          end
          setSprite(npc, src.sprite)
          patchActiveMapObject(mapId, dst.objectIndex,
            src.sprite, src.class, src.member)
          liveShuffleTrainers[npc.id] = {
            npc = npc, gym = physical, destination = dst, source = src,
          }
        end
      end
    end
  end

  -- Gen 1 keeps its native leader and gym-trainer talk scripts intact.
  -- The physical gym owns its full pre-battle -> battle -> reward sequence;
  -- Shuffle changes the live NPC presentation and trainer.party resolution
  -- only. This preserves badge/TM/defeat-flag handling exactly.

  if GEN2 then
  -- Gold/Silver script VM exposes the original leader script key. Rewrite the
    -- intro and trainer-load commands while preserving the physical gym script.
    local BY_SCRIPT={}
    local GEN2_INTROS={
      FALKNER={scriptKey="56:412f",intro="56:41e0"}, BUGSY={scriptKey="55:4d96",intro="55:4e83"},
      WHITNEY={scriptKey="57:400c",intro="57:4122"}, MORTY={scriptKey="52:508f",intro="52:516b"},
      CHUCK={scriptKey="5d:5304",intro="5d:53ee"}, JASMINE={scriptKey="51:4110",intro="51:419a"},
      PRYCE={scriptKey="51:536e",intro="51:545d"}, CLAIR={scriptKey="53:4024",intro="53:40f3"},
      BROCK={scriptKey="5a:405f",intro="5a:40cb"}, MISTY={scriptKey="54:438a",intro="54:45cc"},
      LT_SURGE={scriptKey="59:4bfc",intro="59:4c99"}, ERIKA={scriptKey="5e:5e0b",intro="5e:5ec9"},
      JANINE={scriptKey="5c:40d3",intro="5c:424f"}, SABRINA={scriptKey="61:40cf",intro="61:4180"},
      BLAINE={scriptKey="53:516d",intro="53:51ba"}, BLUE={scriptKey="5f:4002",intro="5f:4057"},
    }
    for id,row in pairs(GEN2_INTROS) do BY_SCRIPT[row.scriptKey]={id=id,intro=row.intro} end
    mod.hooks:wrap("script.command",function(next,ctx,name,args,cmd)
      local physical
      for _,g in ipairs(GYMS) do
        local key=GEN2_INTROS[g.id] and GEN2_INTROS[g.id].scriptKey
        if key and ctx and ctx.scriptKey==key then physical=g; break end
      end
      if not physical or not cmd then return next(ctx,name,args,cmd) end
      local lm=shuffleMapping(); local visitor=lm and SHUFFLE.byId[lm[physical.id]] or physical
      local vr=GEN2_INTROS[visitor.id]
      if name=="writetext" and GEN2_INTROS[physical.id] and cmd.text==GEN2_INTROS[physical.id].intro then
        local rewritten=clone(cmd); rewritten.text=vr and vr.intro or cmd.text; return next(ctx,name,args,rewritten)
      end
      if name=="loadtrainer" and cmd.class==(physical.class or physical.id) and cmd.member==(physical.member or 1) then
        pendingShuffleLeader={physical=physical,visitor=visitor}
        local rewritten=clone(cmd); rewritten.class=visitor.class or visitor.id; rewritten.member=visitor.member or 1
        return next(ctx,name,args,rewritten)
      end
      return next(ctx,name,args,cmd)
    end)
  end

  local function shuffledTrainerPartyFallback(trainerClass, partyIndex)
    local current = mod.world and mod.world:current()
    local physical = current and SHUFFLE.byMap[current.mapId]
    if not physical then return nil end

    local lm = shuffleMapping()
    if not lm then return nil end

    local visitor = SHUFFLE.byId[lm[physical.id]]
    local visitorClass = visitor and (visitor.class or visitor.id)
    local visitorMember = visitor and (visitor.member or visitor.partyIndex or 1)
    if visitor and visitor.id ~= physical.id
      and trainerClass == visitorClass and partyIndex == visitorMember then
      return scaledShuffleParty(visitor.id, physical)
    end

    local tm = trainerMapping()
    if not tm then return nil end
    for _, destination in ipairs(SHUFFLE.trainersByGym[physical.id] or {}) do
      local sourceKey = tm[destination.key]
      local source = sourceKey and SHUFFLE.trainerByKey[sourceKey]
      if source and source.class == trainerClass and source.member == partyIndex then
        return scaledShuffleTrainerParty(source, destination, physical)
      end
    end
    return nil
  end

  mod.hooks:wrap("trainer.party",function(next,trainerClass,partyIndex,party)
    party=next(trainerClass,partyIndex,party)
    local cacheKey = tostring(trainerClass) .. "|" .. tostring(partyIndex)
    if scaledPartyCache[cacheKey] then return scaledPartyCache[cacheKey] end
    if pendingShuffleLeader and trainerClass==(pendingShuffleLeader.visitor.class or pendingShuffleLeader.visitor.id)
      and partyIndex==(pendingShuffleLeader.visitor.partyIndex or pendingShuffleLeader.visitor.member or 1) then
      local p=scaledShuffleParty(pendingShuffleLeader.visitor.id,pendingShuffleLeader.physical)
      local key = tostring(trainerClass) .. "|" .. tostring(partyIndex)
      scaledPartyCache[key] = (#p > 0 and p or party)
      return scaledPartyCache[key]
    end
    if pendingShuffleTrainer and trainerClass==pendingShuffleTrainer.source.class and partyIndex==pendingShuffleTrainer.source.member then
      local p=scaledShuffleTrainerParty(
        pendingShuffleTrainer.source,
        pendingShuffleTrainer.destination,
        pendingShuffleTrainer.gym)
      local key = tostring(trainerClass) .. "|" .. tostring(partyIndex)
      scaledPartyCache[key] = (#p > 0 and p or party)
      return scaledPartyCache[key]
    end

    local fallback = shuffledTrainerPartyFallback(trainerClass, partyIndex)
    if fallback and #fallback > 0 then return fallback end
    return party
  end)


  mod.events:on("world.trainer_engaged",function(event)
    local npc=event and event.npc
    if not npc then return end
    local lr=liveShuffleLeaders[npc.id]
    if lr then
      if GEN2 then npc.def.trainer.class=lr.assigned; npc.def.trainer.member=lr.party
      else npc.def.trainerClass=lr.assigned; npc.def.trainerParty=lr.party end
      pendingShuffleLeader=lr
      pendingShuffleTrainer=nil
      scaledPartyCache={}
      return
    end
    local tr=liveShuffleTrainers[npc.id]
    if tr then
      if GEN2 then npc.def.trainer.class=tr.source.class; npc.def.trainer.member=tr.source.member
      else npc.def.trainerClass=tr.source.class; npc.def.trainerParty=tr.source.member end
      pendingShuffleTrainer=tr
      pendingShuffleLeader=nil
      scaledPartyCache={}
    end
  end)

  mod.events:on("battle.ended", function()
    scaledPartyCache = {}
    pendingShuffleLeader = nil
    pendingShuffleTrainer = nil
  end)

  -- Do not restore the physical trainer class at battle.started. The battle
  -- system may resolve trainer.party more than once, and changing the class
  -- here can make a later lookup fall back to the wrong vanilla party. The
  -- physical gym's reward ownership is preserved by its native map script.

  local LEADER_NAMES = {
    OPP_BROCK="BROCK", OPP_MISTY="MISTY", OPP_LT_SURGE="LT. SURGE", OPP_ERIKA="ERIKA",
    OPP_KOGA="KOGA", OPP_SABRINA="SABRINA", OPP_BLAINE="BLAINE", OPP_GIOVANNI="GIOVANNI",
    FALKNER="FALKNER", BUGSY="BUGSY", WHITNEY="WHITNEY", MORTY="MORTY", CHUCK="CHUCK",
    JASMINE="JASMINE", PRYCE="PRYCE", CLAIR="CLAIR", BROCK="BROCK", MISTY="MISTY",
    LT_SURGE="LT. SURGE", ERIKA="ERIKA", JANINE="JANINE", SABRINA="SABRINA", BLAINE="BLAINE", BLUE="BLUE",
  }

  local function openShuffleSpoiler()
    local mapping=shuffleMapping()
    if not mapping then return end
    local pages={}
    for i,gym in ipairs(GYMS) do
      local visitor=SHUFFLE.byId[mapping[gym.id]] or gym
      pages[#pages+1]=string.format("%d/%d %s\nBADGE %s",i,#GYMS,LEADER_NAMES[visitor.id] or visitor.name or visitor.id,gym.badge:gsub("BADGE$",""))
    end
    local TextBox=require("src.render.TextBox")
    if mod.game and mod.game.stack then mod.game.stack:push(TextBox.new(mod.game,table.concat(pages,"\f"))) end
  end

  mod.events:on("mod.options_changed",function(event)
    local changed=type(event and event.mod)=="table" and event.mod.id or event and event.mod
    if changed~=mod.id then return end
    if event.key=="shuffle_trainers" then mod.save:set("shuffle_trainer_mapping",nil) end
    if event.key=="shuffle_spoiler" and event.value then
      openShuffleSpoiler()
    end
  end)

  mod.events:on("map.entered",function(event)
    if event and event.mapId then
      if shuffleEnabled() then applyShuffleMap(event.mapId) end
    end
  end)

  local PHASES = {}
  if GEN2 then
    PHASES.johto = { first = 1, last = 8 }
    PHASES.kanto = { first = 9, last = 16 }
  else
    PHASES.kanto = { first = 1, last = 8 }
  end

  local STARTER_BY_GENERATION = {
    gen1 = { BULBASAUR=true, CHARMANDER=true, SQUIRTLE=true, PIKACHU=true },
    gen2 = { CHIKORITA=true, CYNDAQUIL=true, TOTODILE=true },
  }

  local state = {
    pendingGuideShop = nil,
    pendingBattle = nil,
    pendingAdvance = false,
    pendingAdvanceChecks = 0,
    pendingAdvanceUntil = nil,
    promptOpen = false,
    shufflePromptOpen = false,
    rushChoice = nil,
    hallPromptOpen = false,
    victoryWarping = false,
  }

  local function rushData()
    return mod.save:get("rush", {})
  end

  local function saveRush(data)
    mod.save:set("rush", data)
  end

  local function freshRush()
    return {
      active = false,
      generation = GENERATION,
      phase = GEN2 and "johto" or "kanto",
      nextGym = 1,
      starterPrompted = false,
      e4Prompted = false,
      complete = false,
    }
  end

  local function normalizeRush(data)
    if type(data) ~= "table" or data.generation ~= GENERATION then
      data = freshRush()
    end
    data.active = data.active == true
    data.nextGym = math.max(1, math.floor(tonumber(data.nextGym) or 1))
    return data
  end

  local function displayNameForTrainer(trainerId, fallback)
    local record = trainerId and mod.content.trainers:get(trainerId)
    if record and type(record.name) == "string" and record.name ~= "" then
      return record.name
    end
    if fallback then return fallback end
    return tostring(trainerId or "UNKNOWN"):gsub("^OPP_", ""):gsub("_", " ")
  end

  local function currentGym(data)
    if GEN2 and data.phase == "kanto" then
      return GYMS[data.nextGym]
    end
    return GYMS[data.nextGym]
  end

  local function stageNumber(data)
    return math.max(1, math.min(#GYMS, tonumber(data.nextGym) or 1))
  end

  local function expMultiplier(data)
    local stage = stageNumber(data)
    if #GYMS <= 1 then return 1.0 end
    return 1.0 + ((stage - 1) / (#GYMS - 1)) * 1.5
  end

  local function tableGetPath(root, paths)
    for _, path in ipairs(paths) do
      local value = root
      for part in string.gmatch(path, "[^%.]+") do
        if type(value) ~= "table" then value = nil; break end
        value = value[part]
      end
      if type(value) == "table" then return value, path end
    end
    return nil
  end

  local function getMoney(game)
    local save = game and game.save
    if not save then return 0, function(_) end end
    if type(save.money) == "number" then
      return save.money, function(v) save.money = v end
    end
    if type(save.player) == "table" and type(save.player.money) == "number" then
      return save.player.money, function(v) save.player.money = v end
    end
    return 0, function(_) end
  end

  local function getBag(game)
    local save = game and game.save
    if type(save) ~= "table" then return nil end

    local direct = {
      "inventory",
      "bag",
      "items",
      "player.inventory",
      "player.bag",
      "player.items",
    }
    local bag = tableGetPath(save, direct)
    if bag then return bag end

    if GEN2 then
      -- Gen 2 builds have used both flat and pocketed bag representations in
      -- development. Prefer an existing generic-item pocket if present.
      if type(save.bag) == "table" then
        if type(save.bag.items) == "table" then return save.bag.items end
        if type(save.bag.ITEMS) == "table" then return save.bag.ITEMS end
        return save.bag
      end
      save.bag = {}
      return save.bag
    end

    save.inventory = {}
    return save.inventory
  end

  local function bagCount(game, itemId)
    local bag = getBag(game)
    if type(bag) ~= "table" then return 0 end
    local value = bag[itemId]
    if type(value) == "number" then return value end
    if type(value) == "table" and type(value.count) == "number" then return value.count end
    return 0
  end

  local function addToBag(game, itemId)
    local bag = getBag(game)
    if type(bag) ~= "table" then return false, "no bag" end

    local current = bag[itemId]
    if current == nil then
      bag[itemId] = 1
      return true
    end
    if type(current) == "number" then
      if current >= 99 then return false, "bag full" end
      bag[itemId] = math.min(99, current + 1)
      return true
    end
    if type(current) == "table" and type(current.count) == "number" then
      if current.count >= 99 then return false, "bag full" end
      current.count = math.min(99, current.count + 1)
      return true
    end
    return false, "unsupported bag entry"
  end

  local function itemName(itemId)
    local item = mod.content.items:get(itemId)
    return item and item.name or tostring(itemId):gsub("_", " ")
  end

  local function itemPrice(itemId)
    local item = mod.content.items:get(itemId)
    return math.max(0, math.floor(tonumber(item and item.price) or 0))
  end

  -- Rush deliberately does NOT mirror the current town's Poké Mart.
  -- The point of this shop is that the player is being pushed through the
  -- Gym sequence and can therefore acquire useful progression supplies
  -- before the ordinary story would make them available.
  local RUSH_STOCK_TIERS = {
    [1] = {
      "POTION", "POKE_BALL", "ANTIDOTE", "PARLYZ_HEAL", "AWAKENING", "BURN_HEAL", "ICE_HEAL",
    },
    [2] = {
      "SUPER_POTION", "GREAT_BALL", "REPEL", "ESCAPE_ROPE", "FULL_HEAL",
    },
    [3] = {
      "HYPER_POTION", "ULTRA_BALL", "SUPER_REPEL", "REVIVE",
      "X_ATTACK", "X_DEFEND", "X_SPEED", "X_SPECIAL", "X_ACCURACY", "GUARD_SPEC", "DIRE_HIT",
    },
    [4] = {
      "MAX_POTION", "MAX_REPEL", "MAX_REVIVE", "FULL_RESTORE",
      "PP_UP", "HP_UP", "PROTEIN", "IRON", "CARBOS", "CALCIUM",
      "FIRE_STONE", "THUNDER_STONE", "WATER_STONE", "LEAF_STONE", "MOON_STONE", "SUN_STONE",
    },
  }

  local function rushShopStock(game, gym)
    local stage = stageNumber(normalizeRush(rushData()))
    local out, seen = {}, {}

    local function add(id)
      if not id or seen[id] or not mod.content.items:get(id) then return end
      seen[id] = true
      out[#out + 1] = id
    end

    for tier = 1, math.min(stage, 4) do
      for _, id in ipairs(RUSH_STOCK_TIERS[tier] or {}) do add(id) end
    end

    -- Unlock the TM catalogue progressively instead of exposing every TM on
    -- the first Gym. The item registry is authoritative for which generation
    -- actually has each TM.
    local tms = {}
    local hms = {}
    for id, item in mod.content.items:each() do
      if type(id) == "string" then
        if id:match("^TM") or (type(item) == "table" and item.machine and item.machine.kind == "TM") then
          tms[#tms + 1] = id
        end
        if id:match("^HM%d+$") then hms[#hms + 1] = id end
      end
    end
    table.sort(tms)
    table.sort(hms)

    if stage >= 4 and #tms > 0 then
      local tmCount = math.min(#tms, 10 + (stage - 4) * 10)
      for i = 1, tmCount do add(tms[i]) end
    end

    -- HMs become progressively available as Rush advances. Gen 1 has five,
    -- Gen 2 has seven; the registry determines the actual set.
    local hmUnlock = { [4] = 2, [5] = 4, [6] = 6, [7] = 7 }
    local hmCount = 0
    for unlockStage, count in pairs(hmUnlock) do
      if stage >= unlockStage then hmCount = math.max(hmCount, count) end
    end
    for i = 1, math.min(hmCount, #hms) do add(hms[i]) end

    if #out == 0 then
      add("POTION")
      add("POKE_BALL")
    end
    return out
  end

  local function findAdjacentWalkable(game)
    local overview = mod.world:mapOverview()
    local pos = mod.world:current()
    if not overview or not pos then return pos and pos.x, pos and pos.y end

    local rows = overview.rows
    local function free(x, y)
      if not rows or not rows[y + 1] then return false end
      local cell = rows[y + 1][x + 1]
      return cell ~= nil and cell ~= false and cell ~= 1 and cell ~= "#" and cell ~= "1"
    end

    local candidates = {
      {pos.x + 1, pos.y}, {pos.x - 1, pos.y},
      {pos.x, pos.y + 1}, {pos.x, pos.y - 1},
    }
    for _, c in ipairs(candidates) do
      if c[1] >= 0 and c[2] >= 0 and free(c[1], c[2]) then
        return c[1], c[2]
      end
    end
    return pos.x, pos.y
  end

  local function clearAdvisor()
    -- Kept as the internal cleanup name for existing rush call sites. The
    -- shop is now attached to the real in-gym guide NPC; nothing is spawned.
    state.pendingGuideShop = nil
  end

  local guideIndexCache = {}
  local function gymGuideIndex(gym)
    if not gym then return nil end
    if guideIndexCache[gym.mapId] ~= nil then
      return guideIndexCache[gym.mapId] or nil
    end

    local map = mod.content.maps:get(gym.mapId)
    local bestIndex, bestScore = nil, -1
    for _, obj in ipairs(map and map.objects or {}) do
      local idx = tonumber(obj and obj.index)
      if idx and idx ~= tonumber(gym.objectIndex) then
        local text = norm(obj.text)
        local name = norm(obj.name)
        local score = -1
        if text:find("gymguide", 1, true) then score = 100 end
        if name:find("gymguide", 1, true) then score = math.max(score, 95) end
        if text:find("gym", 1, true) and text:find("guide", 1, true) then
          score = math.max(score, 90)
        end
        if name:find("guide", 1, true) then score = math.max(score, 80) end
        -- Some Gen 2 extracted objects do not retain the original guide
        -- label but still carry a gym-specific text key. Keep this below the
        -- explicit guide matches so we never steal a trainer or leader.
        if score < 0 and text:find("gym", 1, true) then score = 40 end
        if score > bestScore then
          bestScore, bestIndex = score, idx
        end
      end
    end

    if bestScore >= 80 then
      guideIndexCache[gym.mapId] = bestIndex
      return bestIndex
    end
    guideIndexCache[gym.mapId] = false
    mod.log:warn("Gym Leader Rush: could not identify the native gym guide on %s", tostring(gym.mapId))
    return nil
  end

  local function isCurrentGymGuideInteraction(event, data)
    if not event or event.kind ~= "npc" or not data or not data.active then return false end
    local gym = currentGym(data)
    if not gym then return false end
    local guideIndex = gymGuideIndex(gym)
    if not guideIndex then return false end
    local target = event.target
    if not target then return false end
    local idx = target.def and target.def.index
    if idx == nil then
      local targetId = tostring(target.id or "")
      idx = tonumber(targetId:match("_obj_(%d+)$"))
    end
    local mapId = event.mapId or (target.mapId)
    return mapId == gym.mapId and tonumber(idx) == guideIndex
  end

  local function liveLeaderName(gym)
    local mapping = shuffleMapping()
    local visitor = mapping and SHUFFLE.byId[mapping[gym.id]]
    if visitor then return visitor.name or LEADER_NAMES[visitor.id] or visitor.id, visitor.id end
    local handle = mod.world:npc(gym.mapId, gym.objectIndex)
    local npc = handle and handle.npc
    local trainerId = npc and npc.def and (GEN2 and npc.def.trainer and npc.def.trainer.class or npc.def.trainerClass)
    return displayNameForTrainer(trainerId, gym.name), trainerId
  end

  local function selectEntryWarp(mapId)
    local map = mod.content.maps:get(mapId)
    if not map then return nil end
    local center = (tonumber(map.width) or 20) / 2
    local best
    for _, warp in ipairs(map.warps or {}) do
      if type(warp) == "table" and type(warp.x) == "number" and type(warp.y) == "number" then
        local score = warp.y * 1000 - math.abs(warp.x - center)
        if not best or score > best.score then
          best = { x = warp.x, y = warp.y, score = score }
        end
      end
    end
    if best then return best.x, best.y end
    local width = tonumber(map.width) or 20
    local height = tonumber(map.height) or 20
    return math.floor(width / 2), math.max(1, height - 2)
  end

  local function teleportToGym(data)
    local gym = currentGym(data)
    if not gym then return false end
    clearAdvisor()
    local arrivalMap = gym.arrival.mapId
    local arrivalX, arrivalY = gym.arrival.x, gym.arrival.y
    if GEN2 then
      local x, y = selectEntryWarp(arrivalMap)
      if x then arrivalX, arrivalY = x, y end
    end
    local ok, err = mod.world:warpTo(
      arrivalMap, arrivalX, arrivalY, "up",
      { arrive = "teleport" }
    )
    if not ok then
      mod.log:warn("Gym Leader Rush: gym warp failed: %s", tostring(err))
      return false
    end
    mod.log:info("Gym Leader Rush: sent player to Gym %d (%s)", stageNumber(data), gym.name)
    return true
  end



  local function warpToVictoryRoad(data)
    if state.victoryWarping then return end
    state.victoryWarping = true
    clearAdvisor()

    local candidates = GEN2
      and { "VICTORY_ROAD" }
      or { "VICTORY_ROAD_1F" }

    local mapId
    for _, candidate in ipairs(candidates) do
      if mod.content.maps:get(candidate) then mapId = candidate; break end
    end

    if not mapId then
      state.victoryWarping = false
      mod.log:warn("Gym Leader Rush: could not find a Victory Road map in this imported game")
      return
    end

    local x, y = selectEntryWarp(mapId)
    local ok, err = mod.world:warpTo(mapId, x, y, "up", { arrive = "teleport" })
    if not ok then
      mod.log:warn("Gym Leader Rush: Victory Road warp failed: %s", tostring(err))
    else
      mod.log:info("Gym Leader Rush: Victory Road phase reached")
    end
    state.victoryWarping = false
  end

  local function startRush()
    local data = freshRush()
    data.active = true
    data.phase = GEN2 and "johto" or "kanto"
    data.nextGym = 1
    data.starterPrompted = true
    saveRush(data)
    state.pendingBattle = nil
    state.pendingAdvance = false
    state.hallPromptOpen = false
    teleportToGym(data)
  end

  local function stopRush(complete)
    local data = normalizeRush(rushData())
    data.active = false
    data.complete = complete == true
    saveRush(data)
    clearAdvisor()
    state.pendingBattle = nil
    state.pendingAdvance = false
    state.pendingAdvanceChecks = 0
  end

  local function nextPhaseAfterJohtoE4()
    local data = normalizeRush(rushData())
    data.phase = "kanto"
    data.nextGym = 9
    data.active = true
    data.e4Prompted = true
    saveRush(data)
    teleportToGym(data)
  end

  local function afterGymVictory()
    local data = normalizeRush(rushData())
    local gym = currentGym(data)
    if not data.active or not gym then return end

    if GEN2 and data.phase == "johto" and data.nextGym == 8 then
      data.phase = "johto_e4"
      data.nextGym = 8
      saveRush(data)
      warpToVictoryRoad(data)
      return
    end

    if (not GEN2 and data.nextGym == 8) or (GEN2 and data.phase == "kanto" and data.nextGym == 16) then
      data.phase = "kanto_e4"
      saveRush(data)
      warpToVictoryRoad(data)
      return
    end

    data.nextGym = data.nextGym + 1
    saveRush(data)
    teleportToGym(data)
  end

  local function badgeOwned(game, gym)
    local save = game and game.save
    if type(save) ~= "table" or not gym then return false end

    if not GEN2 then
      -- Current Gen1Recomp stores Gen1 badges as truthy inventory entries.
      local value = save.inventory and save.inventory[gym.badge]
      return value == true or (tonumber(value) or 0) > 0
    end

    -- Gold/Silver/Crystal deliberately keep Johto and Kanto badges in
    -- separate stores. badgeBit is the physical progression bit used by this
    -- mod: 0..7 = Johto, 8..15 = Kanto. The current engine also accepts
    -- name-keyed badge tables, so use the canonical names first and the
    -- positional fallback second.
    local player = save.player or {}
    local badges = (gym.badgeBit or 0) < 8 and player.badges or player.kantoBadges
    if type(badges) ~= "table" then return false end
    if badges[gym.badge] == true then return true end
    local bit = gym.badgeBit
    if bit == nil then return false end
    local index = bit < 8 and bit + 1 or bit - 7
    return badges[index] == true
  end

  local function currentPhysicalGymForEvent(event)
    local npc = event and event.npc
    local mapId = (npc and npc.mapId) or (event and event.mapId)
    local index = (npc and npc.def and npc.def.index) or (npc and npc.index) or (event and event.objectIndex)
    local trainerClass = (npc and npc.def and npc.def.trainerClass) or (npc and npc.trainerClass) or (event and event.trainerClass)
    for i, gym in ipairs(GYMS) do
      if gym.mapId == mapId and (index == nil or gym.objectIndex == index) then
        return gym, i
      end
    end
    -- Some builds omit the object index from the event. A gym map has one
    -- leader object, so the map itself is sufficient in that case.
    if mapId then
      for i, gym in ipairs(GYMS) do
        if gym.mapId == mapId and (trainerClass == nil or trainerClass == gym.id or trainerClass == ("OPP_" .. gym.id)) then
          return gym, i
        end
      end
    end
    return nil, nil
  end

  local function pushNativeYesNo(game, message, defaultNo, callback)
    -- TextBox's documented `choice` path pushes the engine's real ChoiceBox
    -- (YES/NO cursor, input, sound, and cancellation semantics).  Do not use
    -- `instant` here: startup questions are ordinary dialogue prompts and
    -- must type out, then wait for the player to confirm the YES/NO choice.
    local TextBox = require("src.render.TextBox")
    game.stack:push(TextBox.new(game, message, nil, {
      defaultNo = defaultNo == true,
      choice = callback,
    }))
  end

  local function promptRush()
    if state.promptOpen then return end
    state.promptOpen = true
    local game = mod.game
    if not game then state.promptOpen = false; return end
    pushNativeYesNo(game,
      "Would you like to start\nGYM LEADER RUSH?",
      false,
      function(yes)
        state.promptOpen = false
        state.rushChoice = yes == true
        promptShuffle()
      end)
  end

  local function promptShuffle()
    if state.shufflePromptOpen then return end
    state.shufflePromptOpen = true
    local game = mod.game
    if not game then state.shufflePromptOpen = false; return end
    pushNativeYesNo(game,
      "Would you like to use\nGYM LEADER SHUFFLE too?",
      not mod.options:get("shuffle_default"),
      function(yes)
        state.shufflePromptOpen = false
        setShuffleEnabled(yes)

        -- Do not begin the Rush until BOTH startup choices are answered.
        -- That keeps the startup flow in the requested order and prevents the
        -- teleport from happening between the two questions.
        local rushYes = state.rushChoice == true
        state.rushChoice = nil
        if rushYes then
          startRush()
        else
          stopRush(false)
        end
      end)
  end

  local function promptContinue()
    if state.hallPromptOpen then return end
    state.hallPromptOpen = true
    local game = mod.game
    if not game then state.hallPromptOpen = false; return end
    mod.ui.push(game, "GymRushContinuePrompt")
  end

  local function advisorOpen(game)
    local data = normalizeRush(rushData())
    local gym = currentGym(data)
    if not data.active or not gym or not game then return end

    -- Reuse Gen1Recomp's actual Mart UI instead of maintaining a second shop
    -- implementation. This gives us the native BUY/SELL/QUIT menu, cursor,
    -- quantity selector, price confirmation, money display, Bag.add path,
    -- purchase SFX, bag-full handling and thank-you flow for free.
    local stock = rushShopStock(game, gym)
    local menu
    if GEN2 then
      -- Gen 2 uses MartMenu, not the Gen 1 ShopMenu constructor. Supply a
      -- temporary standard-mart shelf so the native Gold/Silver/Crystal BUY /
      -- SELL / QUIT flow, prices, money, and bag rules remain authoritative.
      local MartMenu = require("src.ui.gen2.MartMenu")
      menu = MartMenu.new(game, {
        save = game.save,
        items = game.data and game.data.items,
        marts = { lists = { stock } },
        martId = 0,
        martType = "STANDARD",
        onClose = function() end,
      })
    else
      local ShopMenu = require("src.ui.ShopMenu")
      menu = ShopMenu.new(game, stock, function() end)
    end
    game.stack:push(menu)
  end

  local function starterIsNewGameStarter(ctx, species)
    local current = nil
    if ctx and ctx.overworld and ctx.overworld.map then
      current = ctx.overworld.map.id
    end
    if not current then
      local ok, pos = pcall(function() return mod.world:current() end)
      if ok and pos then current = pos.mapId end
    end
    local mapNorm = norm(current)
    if GEN2 then
      if not mapNorm:find("elmlab", 1, true) then return false end
    else
      if not mapNorm:find("oakslab", 1, true) then return false end
    end
    -- The lab-map boundary is authoritative. Do not whitelist vanilla
    -- starters: Random Starter and species-expansion mods intentionally
    -- replace the Oak/Elm gift with another species.
    return true
  end

  local function pokedexReceived(game)
    local save = game and game.save
    if type(save) ~= "table" then return false end
    if GEN2 then
      local flags = save.engineFlags or {}
      local dexFlag = 11
      local ok, FlagNames = pcall(require, "src.core.gen2.FlagNames")
      if ok and type(FlagNames) == "table" and type(FlagNames.engine) == "table" then
        dexFlag = FlagNames.engine.ENGINE_POKEDEX or dexFlag
      end
      return flags[dexFlag] == true or save.pokedexReceived == true
    end
    local flags = save.flags or save.eventFlags or {}
    return flags.EVENT_GOT_POKEDEX == true
  end

  mod.content.screens:register("GymRushContinuePrompt", {
    new = function(game)
      local self = { isOpaque = true, cursor = 1 }
      function self:update(_dt)
        if game.input:wasPressed("up") or game.input:wasPressed("down") then
          self.cursor = self.cursor == 1 and 2 or 1
        end
        if game.input:wasPressed("a") then
          game.stack:pop()
          state.hallPromptOpen = false
          if self.cursor == 1 then
            nextPhaseAfterJohtoE4()
          else
            stopRush(false)
          end
        elseif game.input:wasPressed("b") then
          game.stack:pop()
          state.hallPromptOpen = false
          stopRush(false)
        end
      end
      function self:draw()
        mod.ui.Font.drawBox(0, 0, 20, 18)
        mod.ui.Font.draw("JOHTO E4 CLEARED", 8, 8)
        mod.ui.Font.draw("Continue to KANTO?", 8, 32)
        mod.ui.Font.draw((self.cursor == 1 and "> " or "  ") .. "YES", 8, 64)
        mod.ui.Font.draw((self.cursor == 2 and "> " or "  ") .. "NO", 8, 80)
        mod.ui.Font.draw("A=OK  B=CANCEL", 8, 136)
      end
      return self
    end,
  })

  mod.hooks:wrap("save.new_game", function(next, save)
    save = next(save)
    saveRush(freshRush())
    state.pendingBattle = nil
    state.pendingAdvance = false
    state.pendingAdvanceChecks = 0
    state.pendingAdvanceUntil = nil
    state.rewardSeen = false
    state.promptOpen = false
    state.shufflePromptOpen = false
    state.rushChoice = nil
    state.hallPromptOpen = false
    mod.save:set("shuffle_enabled", false)
    mod.save:set("shuffle_mapping", nil)
    mod.save:set("shuffle_trainer_mapping", nil)
    mod.save:set("shuffle_held_mapping", nil)
    return save
  end)

  mod.events:on("pokemon.before_give", function(event)
    if not event or not event.species then return end
    if starterIsNewGameStarter(event.ctx, event.species) then
      local data = normalizeRush(rushData())
      if not data.starterPrompted and not data.complete then
        data.starterPrompted = false
        mod.save:set("starter_pending", true)
        saveRush(data)
      end
    end
  end)

  local function maybePromptStarter()
    local data = normalizeRush(rushData())
    if data.starterPrompted or data.active or data.complete then
      mod.save:set("starter_pending", nil)
      return
    end
    if mod.save:get("starter_pending", false) ~= true then return end
    if state.promptOpen or state.shufflePromptOpen then return end
    local game = mod.game
    if not game or not pokedexReceived(game) then return end
    mod.save:set("starter_pending", nil)
    -- Startup order is intentional: Rush first, then optional Shuffle.
    promptRush()
  end

  mod.events:on("script.ended", function()
    maybePromptStarter()
  end)

  -- Pokédex acquisition is the real progression boundary. Do not depend on
  -- the starter gift script ending or a particular map transition to notice it.
  mod.events:on("flag.changed", function(event)
    if not (event and event.value and event.name) then return end
    local name = tostring(event.name)
    if name == "EVENT_GOT_POKEDEX" or name == "ENGINE_POKEDEX" then
      maybePromptStarter()
    end
  end)

  mod.events:on("map.entered", function(event)
    local data = normalizeRush(rushData())
    state.pendingGuideShop = nil
    if mod.save:get("starter_pending", false) then
      maybePromptStarter()
    end

    if event and event.mapId == "HALL_OF_FAME" and GEN2 then
      if data.active and (data.phase == "johto_e4" or data.phase == "kanto_e4") and not state.hallPromptOpen then
        if data.phase == "kanto_e4" then
          stopRush(true)
        else
          promptContinue()
        end
      end
    end

    if not data.active then
      clearAdvisor()
      return
    end

    if not currentGym(data) then return end
  end)

  mod.events:on("world.interacted", function(event)
    local data = normalizeRush(rushData())
    if isCurrentGymGuideInteraction(event, data) then
      state.pendingGuideShop = {
        mapId = event.mapId,
        objectIndex = event.target and event.target.def and event.target.def.index,
      }
    end
  end)

  -- Some builds complete the guide's text through ScriptRunner before the
  -- final TextBox state is popped; use both seams so the shop opens on the
  -- same frame the dialogue ends, without waiting for a movement tick.
  mod.events:on("script.ended", function(event)
    if not state.pendingGuideShop or event and event.completed == false then return end
    local game = mod.game
    local pos = mod.world:current()
    local top = game and game.stack and game.stack:top()
    if top and top.isOverworld and pos
        and pos.mapId == state.pendingGuideShop.mapId then
      state.pendingGuideShop = nil
      advisorOpen(game)
    end
  end)

  mod.events:on("world.trainer_engaged", function(event)
    local data = normalizeRush(rushData())
    if not data.active then return end
    local gym, index = currentPhysicalGymForEvent(event)
    if not gym or index ~= data.nextGym then return end

    local game = mod.game
    state.pendingBattle = {
      stage = index,
      mapId = gym.mapId,
      npcId = event.npc and event.npc.id,
      hadBadge = badgeOwned(game, gym),
    }
    state.pendingAdvance = false
    state.pendingAdvanceChecks = 0
    state.pendingAdvanceUntil = nil
    state.rewardSeen = false
  end)

  mod.events:on("world.blacked_out", function()
    state.pendingBattle = nil
    state.pendingAdvance = false
    state.pendingAdvanceChecks = 0
  end)

  local function clearPendingBattle()
    state.pendingBattle = nil
    state.pendingAdvance = false
    state.pendingAdvanceChecks = 0
    state.pendingAdvanceUntil = nil
    state.rewardSeen = false
  end

  local function tryAdvanceAfterBattle()
    local pending = state.pendingBattle
    if not pending then return end
    local data = normalizeRush(rushData())
    if not data.active or pending.stage ~= data.nextGym then
      clearPendingBattle()
      return
    end

    local game = mod.game
    local gym = GYMS[pending.stage]
    if not gym then
      clearPendingBattle()
      return
    end

    -- A pre-existing badge cannot be used as proof that this battle was won.
    if pending.hadBadge then
      clearPendingBattle()
      return
    end

    if badgeOwned(game, gym) then
      clearPendingBattle()
      afterGymVictory()
      return
    end

    if state.rewardSeen then
      -- A flag.changed reward can arrive before the derived badge container is
      -- refreshed. Wait for the same short grace window rather than throwing
      -- away a confirmed victory.
      state.pendingAdvance = true
    end

    -- The battle screen can close before the native gym script writes the
    -- badge/defeat flag. Keep the engagement alive for a real grace window;
    -- flag.changed below is the authoritative fast path when the reward lands.
    state.pendingAdvance = true
    state.pendingAdvanceChecks = (state.pendingAdvanceChecks or 0) + 1
    local now = (love and love.timer and love.timer.getTime and love.timer.getTime()) or os.clock()
    state.pendingAdvanceUntil = state.pendingAdvanceUntil or (now + 3.0)
    if state.pendingAdvanceChecks > 60 or now > state.pendingAdvanceUntil then
      clearPendingBattle()
    end
  end

  local function gymRewardFlagMatches(event, gym)
    if not (event and event.value and event.name and gym) then return false end
    local name = tostring(event.name)
    local id = tostring(gym.id):gsub("^OPP_", "")
    if name == "EVENT_BEAT_" .. id then return true end
    if GEN2 then
      local engineName = "ENGINE_" .. tostring(gym.badge) .. "BADGE"
      if name == engineName then return true end
      -- Gen2 flag.changed uses the numeric engine flag id in `name`.
      local ok, FlagNames = pcall(require, "src.core.gen2.FlagNames")
      if ok and type(FlagNames) == "table" then
        local engine = FlagNames.engine or {}
        local events = FlagNames.event or FlagNames.events or {}
        if tonumber(event.name) == tonumber(engine[engineName])
            or tonumber(event.name) == tonumber(events["EVENT_BEAT_" .. id]) then
          return true
        end
      end
    end
    return false
  end

  mod.events:on("flag.changed", function(event)
    local pending = state.pendingBattle
    if not pending then return end
    local data = normalizeRush(rushData())
    if not data.active or pending.stage ~= data.nextGym then return end
    local gym = GYMS[pending.stage]
    if not gym or pending.hadBadge or not gymRewardFlagMatches(event, gym) then return end
    -- The reward flag is the authoritative proof that the native gym script
    -- completed. Defer the actual warp to the normal overworld seam so the
    -- final reward dialogue can finish cleanly.
    state.pendingAdvance = true
    state.pendingAdvanceChecks = 0
    state.pendingAdvanceUntil = ((love and love.timer and love.timer.getTime and love.timer.getTime()) or os.clock()) + 3.0
    state.rewardSeen = true
  end)

  mod.events:on("screen.popped", function(event)
    if state.pendingGuideShop then
      local game = mod.game
      local pos = mod.world:current()
      local top = game and game.stack and game.stack:top()
      if top and top.isOverworld and pos
          and pos.mapId == state.pendingGuideShop.mapId then
        state.pendingGuideShop = nil
        advisorOpen(game)
      end
    end
    tryAdvanceAfterBattle()
  end)

  mod.events:on("world.stepped", function()
    maybePromptStarter()

    if state.pendingAdvance then tryAdvanceAfterBattle() end
  end)

  mod.hooks:wrap("exp.gain", function(next, ctx)
    local gained = next(ctx)
    local data = normalizeRush(rushData())
    if not data.active then return gained end
    local multiplier = expMultiplier(data)
    local scaled = math.floor(gained * multiplier + 0.5)
    if mod.options:get("show_exp_multiplier") then
      mod.log:info("Gym Leader Rush EXP: %d x %.2f = %d", gained, multiplier, scaled)
    end
    return scaled
  end)

  mod.events:on("game.ready", function()
    -- No synthetic advisor is spawned. The native gym guide is the shopkeeper.
    maybePromptStarter()
  end)

  mod.log:info("Gym Leader Rush loaded for %s (Gen %d)", VERSION, GENERATION)
end
