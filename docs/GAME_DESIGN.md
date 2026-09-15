# GAME_DESIGN.md — Project Red Gate

Owner: Lead / Architect
Status: Phase 0 (Foundation)

This is the source of truth for what the game *is*. If code and this
document disagree, this document wins until the Lead Agent updates it.

---

## 1. Working Title

**Project Red Gate**

## 2. Genre & Presentation

- Single-player RPG
- 2D pixel art with depth (parallax, layering, elevation cues)
- Command/menu-based combat
- Dungeon exploration
- Gear-driven progression
- Mystery/discovery-driven Gate system

This is **not** an MMO. No accounts, no live service, no matchmaking,
no persistent shared world. All systems are local, single-player, and
save/load to a local file.

## 3. Core Fantasy

The world was torn apart by a cataclysm known as **the Fracture**. What
used to be one continent is now a scatter of disconnected fragments
called **Reaches**. The only way to travel between Reaches is through
**Gates**: dormant stone arches that only activate when the correct
three-word keyword combination is spoken into them.

Most Gate combinations are known and catalogued by the scholars of the
last standing settlement. Some are not. Adventurers who go looking for
uncatalogued combinations occasionally find nothing. Sometimes they find
somewhere new. And a very small number of people insist that if you find
the *right* wrong combination, the arch doesn't glow its usual color —
it turns red — and you should immediately have their attention when you
get back.

The player is one such adventurer: explore, fight, get stronger, decode
Gate keyword clues, and use that strength to prove or disprove the
rumor of the **Red Gate**.

The player should constantly wonder:
- What does this Gate combination do?
- What is hidden on this map?
- Why is this enemy different?
- Is there a better weapon here?
- What happens if I combine these Gate words?
- Is this ordinary loot or something special?
- Is the Red Gate real?

## 4. Core Game Loop

```
Waymark (town)
  -> choose Gate keywords
  -> enter map
  -> explore
  -> encounter enemy
  -> command-based combat
  -> win
  -> receive XP / currency / equipment
  -> equip / upgrade
  -> discover a Gate clue
  -> enter the correct (special) combination
  -> enter the Red Gate
  -> obtain the unique reward
  -> return to Waymark
  -> become stronger
  -> repeat
```

The Gate system is a core progression and exploration mechanic, not
decoration. It must be data-driven (see ARCHITECTURE.md).

## 5. World & Lore (original, no borrowed IP)

- **World name:** The Reaches (the fragments left after the Fracture)
- **Town:** **Waymark** — a settlement built around a cluster of long
  dormant Gates; the only safe hub in the prototype.
- **The Fracture:** the world-breaking event, backstory only, never a
  place the player visits directly in the prototype.
- **The Red Gate:** a rumored Gate combination that does not appear in
  any Waymark catalogue. Finding it is the spine of the vertical slice.

No terminology, names, characters, or keywords from *.hack* or
*Conquer Online* are used. Gate categories and words below are original.

## 6. Gate System

A Gate combination is three keywords, one from each category:

```
[ORIGIN] + [TONE] + [SIGN]
```

### Prototype keyword pool

**ORIGIN** (place-flavor)
- Cinder
- Verdant
- Drowned
- Hollow

**TONE** (mood/modifier)
- Silent
- Broken
- Forgotten
- Undying

**SIGN** (elemental attribute)
- Ember
- Tide
- Gale
- Umbra

### Prototype combinations

| Combination | Result |
|---|---|
| `Cinder + Broken + Ember` | Normal map: **Cinderfall Woods** |
| `Drowned + Silent + Tide` | Normal map: **The Silent Marsh** |
| `Hollow + Undying + Ember` | **SPECIAL** — opens the Red Gate |
| any other known ORIGIN/TONE/SIGN triple not listed | "Unknown combination" (data-driven placeholder, safe no-op) |
| a keyword not in the pool, or malformed input | "Invalid combination" (rejected safely, no crash) |
| a catalogued triple the player hasn't unlocked yet | "Locked combination" |

The Red Gate combination is never shown directly to the player. It must
be pieced together from Gate discovery sources (Section 8).

Gate resolution logic lives entirely in `/scripts/gates/` and reads its
combination table from `/data/gates/`. No combination is hardcoded into
UI, combat, or world scripts.

## 7. Maps

### Town — Waymark
- Player spawn
- One shop NPC (buy/sell, equip)
- Gate interface (enter keyword combinations)
- Save point

### Normal Map 1 — Cinderfall Woods
- Reached via `Cinder + Broken + Ember`
- Early-game enemies, first equipment tier
- One branching exploration path (a side area with bonus loot)

### Normal Map 2 — The Silent Marsh
- Reached via `Drowned + Silent + Tide`
- Slightly harder enemies, second equipment tier
- Contains an environmental Gate clue (Section 8)

### Special Map — The Red Gate
- Reached via `Hollow + Undying + Ember`
- Distinct palette (deep red/black), distinct ambience
- Unique enemy + boss: **the Ashen Warden**
- Contains the unique weapon: **Cindermourn**
- Not a recolor of the normal maps — different tileset, different
  encounter table, different music cue hook

## 8. Gate Discovery

The prototype needs 2–4 sources, each revealing a fragment of the Red
Gate combination or a hint towards it:

1. **NPC hint** — the Waymark shopkeeper mentions a rumor after the
   player reaches a level/gold threshold.
2. **Item description** — a dropped item's flavor text names one
   keyword outright.
3. **Environmental clue** — an inspectable object in The Silent Marsh.
4. **Boss drop** — defeating a normal-map mini-boss drops a note
   confirming the final keyword.

Each source is data (see `/data/gates/`), not a hardcoded string buried
in a scene script.

## 9. Combat

Command/menu based. No hitboxes, no action-game movement, no timing
minigames in the prototype.

Flow: enter encounter -> show party/enemy state -> choose command ->
resolve -> show result -> repeat until victory/defeat.

Commands: **Attack, Skill, Item, Defend, Run**.

### Enemies (prototype set)
- Ember Wisp (Cinderfall Woods, common)
- Bramble Husk (Cinderfall Woods, common)
- Tideling (Silent Marsh, common)
- Hollow Stalker (Silent Marsh, common)
- Cinder Wraith (Cinderfall Woods, mini-boss, drops a Gate clue)
- **Ashen Warden** (Red Gate boss)

### Player abilities (prototype set, 3–5)
- Basic Attack (free, weapon-scaled)
- Ember Slash (low MP, single target, fire-flavored)
- Guard Break (medium MP, bonus vs. defending enemies)
- Second Wind (MP, self-heal)
- (5th ability reserved for post-Phase-2 tuning)

## 10. Player Progression

- XP and Levels
- Stats: **HP, MP, Attack, Defense, Magic Power, Speed** (deliberately
  small — do not add stats without a demonstrated need)
- Equipment slots: **Weapon, Armor, Accessory**
- Currency: **Glimmer** (single currency, no premium currency)

## 11. Gear & Rarity

Rarity tiers: **Common, Uncommon, Rare, Unique**.

Every item has: name, description, rarity, level requirement (optional),
stat block, optional special effect, value, source.

### Example progression (illustrative, not final balance)

| Item | Rarity | Stats | Notes |
|---|---|---|---|
| Rusted Shortsword | Common | +6 Attack | Waymark shop |
| Cinderfall Cleaver | Uncommon | +14 Attack | Cinderfall Woods drop |
| Marshfang Blade | Rare | +28 Attack | Silent Marsh drop |
| Warden's Edge | Rare | +42 Attack | Normal top-end weapon |
| **Cindermourn** | **Unique** | +35 Attack, +15% damage vs. the Ashen family, restores 5 MP on kill | Red Gate reward — identity over raw numbers |

Cindermourn is deliberately *not* just a bigger number than Warden's
Edge. It trades raw Attack for a build-defining effect, per the design
pillar in Section 4 of CLAUDE.md.

## 12. Design Pillars (from CLAUDE.md, restated for quick reference)

Every feature must support at least one of: Exploration, Discovery,
Character progression, Gear excitement, Strategic combat, Mystery,
Replayability.

## 13. Playable Vertical-Slice Definition

The first milestone is complete only when a player can, in one sitting:
launch the game, start a new game, walk around Waymark, open the Gate
interface, enter Cinderfall Woods, explore, fight, win, get XP and loot,
equip an item, discover a Red Gate clue, enter the correct combination,
reach the Red Gate map, beat the Ashen Warden, obtain and equip
Cindermourn, feel meaningfully stronger, and return to Waymark.

## 14. Explicit Non-Goals for the Prototype

No multiplayer, no MMO servers, no guilds/auctions/trading, no PvP, no
massive procedural worlds, no hundreds of items, no crafting (unless a
later phase proves it essential), no complex quest trees, no voice
acting, no character creator, no class roster, no skill trees. See
CLAUDE.md Section 24 for the full list; this list must not grow without
a Lead Agent decision recorded in PROGRESS.md.
