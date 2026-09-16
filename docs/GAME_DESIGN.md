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
- Frost *(added content-expansion pass — its own icy floor theme)*
- Storm *(added content-expansion pass — its own stormy floor theme)*

**TONE** (mood/modifier)
- Silent
- Broken
- Forgotten
- Undying
- Ancient *(added content-expansion pass — the first Tone word past level 4)*

**SIGN** (elemental attribute)
- Ember
- Tide
- Gale
- Umbra
- Fracture *(added content-expansion pass — as branching/dangerous as Umbra; a deliberate lore callback to Section 3's Fracture, and the pool's first two-words-one-tier case)*

### How a combination resolves (Phase 5 — implemented)

Every well-formed combination does *something* — the words themselves
determine what, rather than most combinations being an "Unknown"
no-op. This is a deliberate design change from the original "catalogued
rows only" plan (see AGENT_CONTRACTS.md's decision log), made to match
the *.hack*-inspired feel the CLAUDE.md brief asked for: any three
words open onto somewhere, and which words you choose determines what
kind of somewhere.

| Combination | Result |
|---|---|
| `Hollow + Undying + Ember` | **SPECIAL** — opens the Red Gate (see below) |
| `Cinder + Broken + Ember` | Normal map: **Cinderfall Woods** (the one hand-crafted normal dungeon) |
| any other well-formed `ORIGIN + TONE + SIGN` triple | **GENERATED** — a dungeon built from that combination's own words (see "Word-driven generation" below) |
| a keyword not in the pool, or an incomplete selection | "Invalid combination" (rejected safely, no crash) |

The Red Gate combination is never shown directly to the player. It must
be pieced together from Gate discovery sources (Section 8).

Gate resolution logic lives entirely in `/scripts/gates/` (`GateResolver`)
and reads its known/special rows from `/data/gates/combinations/`. No
combination is hardcoded into UI, combat, or world scripts.

### Gate preview (depth pass, post-Phase-6)

Choosing 3 words used to be a total blind commitment — no idea what
level, size, or monsters waited on the other side until you'd already
opened the Gate. Once all 3 are picked, the Gate UI now shows a
preview: for a generated result, the real level, a size description,
and which monsters you're likely to meet; for the Red Gate or
Cinderfall Woods, a short evocative line instead, so the two hand-built
destinations keep their mystery rather than being spoiled outright.
Choosing an invalid combination shows a hint that the words don't fit,
before you even try to open it.

### Word-driven generation

Each word category maps onto a different axis of the generated
dungeon, so the words genuinely change what you get, not just where you
end up:

| Word category | Controls | Prototype values |
|---|---|---|
| **ORIGIN** | Visual theme (floor tile palette), and which enemies spawn | Cinder=ash, Verdant=lush green, Drowned=teal/wet, Hollow=dark void, Frost=icy blue, Storm=stormy grey |
| **TONE** | Enemy level (1-5), which scales enemy stats and which loot tier drops | Silent=1, Broken=2, Forgotten=3, Undying=4, Ancient=5 |
| **SIGN** | Dungeon shape/size (0-3 side branches) | Ember=0 (small, single room), Gale=1, Tide=2, Umbra=3 / Fracture=3 (large, most branching) |

A generated dungeon reused the same two Cinderfall Woods enemies (Ember
Wisp, Bramble Husk) at the computed level for every Origin through
Phase 6. The content-expansion pass gave **Verdant** and **Drowned**
their own themed enemy — the tanky **Thornling** and the caster
**Brinewisp**, respectively — alongside one of the originals; every
other Origin (Cinder, Hollow, and the new Frost/Storm) still uses the
shared duo. This is a deliberate partial step, not full per-Origin
monster variety (still mindful of Section 24's scope discipline) — see
AGENT_CONTRACTS.md's Open Interface Decisions Log.

The *shape* of a dungeon (which physical layout template a given branch
tier uses) is currently one of 4 fixed templates, not a unique random
layout per word triple; see ARCHITECTURE.md Section 7a for the reasoning
(this sandbox has no display to catch a broken randomly-generated
layout, so the layout itself stays deterministic and pre-verified while
level/theme/loot still vary with the words). Fracture reuses Umbra's
template (tier 3) rather than adding a genuinely new, unverified 5th
one.

**Scale and packs (depth pass, post-Phase-6):** every tier's map size
and encounter count grew substantially in response to playtesting —
dungeons read as flat and empty, with only 1-4 solo enemies to fight
across an entire run. Tier 0 (small, single room) now has 2 encounters
where it had 1; tier 3 (largest, most branching) has 7 where it had 4,
plus 1-2 loot chests per tier (none at tier 0). Each encounter now
spawns a **pack** of 2-3 enemies rather than always a single one —
bosses and the Cinder Wraith mini-boss stay solo fights.

## 7. Maps

### Town — Waymark
- Player spawn
- One shop NPC (buy/sell, equip)
- Gate interface (enter keyword combinations)
- Save point

### Cinderfall Woods — the one hand-crafted normal dungeon
- Reached via `Cinder + Broken + Ember`
- Early-game enemies, first equipment tier
- Enlarged in the depth pass (post-Phase-6): two branching exploration
  paths now — the original north branch leading to the Cinder Wraith
  mini-boss, and a new south branch holding a loot chest — plus 5
  monster-pack encounters along the way (up from 3 solo fights)
- Kept hand-crafted (not generated) specifically so the game's very
  first dungeon has a designed, tested shape rather than a formulaic
  template — see Section 25's discovery→reward→power loop.

### Every other normal destination — generated, not curated

**The Silent Marsh, as a distinct hand-authored map, is superseded by
Phase 5's word-driven generation system** (see Section 6). Its planned
combination, `Drowned + Silent + Tide`, was never built as a real scene
(only stubbed data through Phase 4) — it now simply generates a
Drowned-themed, level-1, single-branch dungeon like any other
`Drowned + Silent + *` combination, rather than pointing at a dedicated
map. This is a deliberate design supersession, not an oversight: with
every valid combination now producing *something*, a second hand-built
"normal map" alongside Cinderfall Woods stopped pulling its weight.

### Special Map — The Red Gate
- Reached via `Hollow + Undying + Ember`
- Distinct palette (deep red/black), distinct ambience
- Boss: **the Ashen Warden** (family `"ashen"`, guaranteed fight, can't
  be fled from)
- Contains the unique weapon: **Cindermourn** — +35 Attack, +15%
  damage vs. the `"ashen"` family, restores 5 MP on kill (implemented
  exactly as originally specified in Section 11's example)
- Not a recolor of the normal maps — its own tileset color, its own
  hand-placed layout, not the generation system used elsewhere

### Presentation (Phase 6)

Every dungeon (Cinderfall Woods, every generated dungeon, and the Red
Gate) is now dimmed with a soft light following the player, so
exploring reads as tenser/darker than Waymark's bright safe hub — a
lighting cue built entirely from engine primitives (no new art assets;
see ARCHITECTURE.md Section 7b). Town is intentionally left fully lit.
This is the first "elevation/lighting cue" from Section 2's genre list
to actually ship; full parallax/depth layering is still future work.

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

### Monster packs (depth pass, post-Phase-6)

Most encounters are now against a pack of 2-3 enemies rather than a
single one — bosses and the Cinder Wraith mini-boss stay solo fights.
Attacking or using a single-target Skill against more than one living
enemy opens a target-select menu; with only one enemy left alive,
targeting happens automatically with no extra click. Every pack member
still acts on its own turn, but each hits somewhat softer than it would
solo (100%/85%/70% of its normal damage for a 1/2/3-enemy pack) — the
same trade-off most JRPGs make so "more enemies" means a longer, more
chaotic fight rather than proportionally more incoming damage per
round. Victory rewards (XP, gold) sum across the whole pack; loot still
rolls only once per battle, not once per enemy.

### Damage & initiative (systems-depth pass, post-Phase-5)

Damage no longer subtracts defense flat from power. Every hit runs
through `CombatMath.mitigate()`: a diminishing-returns curve,
`mitigation = defense/(defense+40)`, so defense is always worth
something but can never make a unit unhittable (a raw hit of at least 1
always lands). Skills scale off Attack if their `element` is
`"physical"`, or Magic Power for every other element (fire, etc.) — so
gearing Magic Power now matters for elemental skills the way Attack
always mattered for weapon damage.

Whoever has the higher effective Speed opens the battle; ties default to
the player. Speed existed as a stat since Phase 0 but had no gameplay
effect until now. Only the opening turn is speed-checked — turns
alternate normally afterward, there's no full speed-queue/ATB system in
this prototype.

**Balance finding (not a bug):** an undefended level-1 player cannot
survive the Ashen Warden's opening Ashfall — its raw power exceeds a
level-1 player's base 20 HP once mitigated. This is a direct, working
consequence of the new formula and the intended stakes of the Red
Gate's boss, not something to silently patch around; a player is
expected to gear up (e.g. Traveler's Vest for +5 HP/+3 Defense) before
attempting the Red Gate. Noted here per Section 27's "measure then
adjust" philosophy rather than tuned away.

### Combat feedback & sound (Phase 6)

Hits now land with a screen-tint flash, a short screen shake, and a
sound cue; victory, defeat, and fleeing each get their own short
jingle. Every sound is synthesized at runtime rather than a recorded
audio file — this sandbox has no way to source or license real audio
assets, so a short procedural tone stands in, the same way a ColorRect
stands in for real tile art (see ARCHITECTURE.md Section 8a). It is
built to be swapped for real SFX later without changing anything that
calls it.

### Weapon movesets (systems-depth pass, post-Phase-5)

Weapons can grant an extra Skill only usable while that weapon is
equipped, on top of the 3 universal skills every player always has:
- **Cinderfall Cleaver** grants **Cleave** (physical, single target)
- **Cindermourn** grants **Ashbrand** (fire, single target, high power)

This makes gear a build choice beyond raw stat totals — switching
weapons changes what moves are available, not just the numbers behind
Basic Attack.

### Enemy AI & boss mechanics (Phase 6)

Every enemy alternates basic attack and its one skill turn-to-turn
instead of spamming the skill every time (the previous behavior for
every enemy in the game). The **Ashen Warden** additionally **enrages**
at 50% HP: it permanently switches to **Cinderquake** (power 24, its
strongest attack, versus Ashfall's 14) for the rest of the fight, with
a one-time "The Ashen Warden's flames roar higher!" warning. This turns
the fight into two phases — survive the opening exchanges, then weather
a harder back half — without needing a full scripted-phase boss AI
framework the prototype's single boss doesn't justify yet.

### Enemies (prototype set — 6, content-expansion pass)
- Ember Wisp (common — Cinderfall Woods, and the default reused enemy
  in most generated dungeons; see Section 6's word-driven generation)
- Bramble Husk (common — same reuse as Ember Wisp)
- **Thornling** (common — Verdant-origin dungeons only; tankier/slower
  than the two above, physical)
- **Brinewisp** (common — Drowned-origin dungeons only; the first
  common enemy built around Magic Power rather than Attack)
- Cinder Wraith (Cinderfall Woods mini-boss, drops a Gate clue)
- **Ashen Warden** (Red Gate boss — the only enemy with an enrage phase)

Tideling and Hollow Stalker were originally planned as Silent Marsh's
enemies; since Silent Marsh as a distinct hand-authored map is
superseded by Phase 5's generation system (see Section 7), they're
still not built — Thornling/Brinewisp are new content, not a revival
of those two. Cinder, Hollow, Frost, and Storm dungeons still reuse
Ember Wisp/Bramble Husk rather than getting unique monsters, a
deliberate partial (not full) revision of CLAUDE.md's "3-5 enemy
types" scope guidance — see AGENT_CONTRACTS.md's decision log.

### Player abilities (prototype set, 5 — filled out in the depth pass)
- Basic Attack (free, weapon-scaled)
- Ember Slash (low MP, single target, fire-flavored)
- Guard Break (medium MP, bonus vs. defending enemies)
- Second Wind (MP, self-heal)
- **Blazing Arc** (medium MP, hits the whole enemy pack at once,
  fire-flavored) — fills the 5th slot reserved since Phase 2, added
  specifically to give players a real answer to monster packs

## 10. Player Progression

- XP and Levels
- Stats: **HP, MP, Attack, Defense, Magic Power, Speed** (deliberately
  small — do not add stats without a demonstrated need)
- Equipment slots: **Weapon, Armor, Accessory**
- Currency: **Gold** (single currency, no premium currency — renamed
  from this doc's original "Glimmer" once implementation settled on
  the plainer name; noted here so the two don't drift apart again)

## 11. Gear & Rarity

Rarity tiers: **Common, Uncommon, Rare, Unique**.

Every item has: name, description, rarity, level requirement (optional),
stat block, optional special effect, value, source.

`level_requirement` existed on every item since Phase 0 but was
unenforced until the systems-depth pass — `EquipmentManager.can_equip()`
now gates the Equip button in the inventory screen, so gear
progression actually paces with player level instead of being
available from turn one.

### Progression, as actually implemented (Phases 3-6, content-expansion pass)

| Item | Rarity | Req. Lv | Stats | Moveset | Source |
|---|---|---|---|---|---|
| Rusted Shortsword | Common | 1 | +6 Attack | — | Waymark shop |
| Traveler's Vest | Common | 1 | +3 Defense, +5 max HP | — | Waymark shop |
| Lucky Charm | Common | 1 | +2 Speed | — | Waymark shop |
| Windward Ring | Uncommon | 1 | +4 Speed, +5 max MP | — | Generated dungeon drop (low tier) |
| Cinderfall Cleaver | Uncommon | 2 | +14 Attack | Cleave | Cinderfall Woods / generated-dungeon drop |
| Verdant Fang | Uncommon | 2 | +12 Attack | Piercing Thorn | Generated dungeon drop (mid tier) |
| Iron Buckler | Uncommon | 2 | +7 Defense, +3 max HP | — | Generated dungeon drop (mid tier) |
| Brinewoven Robe | Uncommon | 2 | +4 Defense, +6 Magic Power | — | Generated dungeon drop (mid tier) |
| Ashcinder Guard | Rare | 2 | +10 Defense, +10 max HP | — | Cinder Wraith drop, or a level-4 generated dungeon |
| Stormcaller Pendant | Rare | 3 | +6 Magic Power, +3 Speed | — | Generated dungeon drop (high tier only) |
| **Cindermourn** | **Unique** | 3 | +35 Attack, +15% damage vs. the `"ashen"` family, restores 5 MP on kill | Ashbrand | Ashen Warden (Red Gate) drop — the only guaranteed unique |

Cindermourn is deliberately *not* just a bigger number than the Rare
tier above it. It trades some of the raw Attack a min-maxed build might
want for a build-defining effect, per the design pillar in Section 4 of
CLAUDE.md — and unlike the earlier illustrative draft of this table,
every row here is real, implemented content, not a placeholder example.

Brinewoven Robe and Stormcaller Pendant are the first items to raise
Magic Power at all — every elemental Skill has scaled off that stat
since the systems-depth pass, but no gear touched it until this pass,
so a caster-leaning build had nothing to invest in. Windward Ring and
Stormcaller Pendant likewise lean on Speed, meaningful since Phase 6
made it decide combat initiative.

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
